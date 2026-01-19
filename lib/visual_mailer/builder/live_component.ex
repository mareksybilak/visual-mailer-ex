if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule VisualMailer.BuilderComponent do
    @moduledoc """
    LiveView component for the visual email editor.

    This component integrates the `visual-mailer` NPM package's React editor
    with Phoenix LiveView, providing seamless two-way communication.

    ## Usage

        <.live_component
          module={VisualMailer.BuilderComponent}
          id="email-builder"
          template={@template}
          config={%{
            brand_color: "#007bff",
            brand_logo: "/images/logo.png"
          }}
          variables={[
            %{key: "first_name", label: "First Name"},
            %{key: "company", label: "Company"}
          ]}
          on_save={fn data -> send(self(), {:template_saved, data}) end}
          on_autosave={fn data -> send(self(), {:template_autosaved, data}) end}
          on_image_upload={&upload_image/1}
        />

    ## Callbacks

    - `on_save` - Called when user clicks "Save". Receives `%{content_json: ..., mjml_cache: ..., html_cache: ...}`
    - `on_autosave` - Called periodically with draft data. Receives `%{content_json: ...}`
    - `on_image_upload` - Called when user uploads an image. Should return `{:ok, url}` or `{:error, reason}`

    ## JavaScript Setup

    Make sure to add the hook to your `app.js`:

        import { EmailBuilderHook } from "visual-mailer/hooks";

        let liveSocket = new LiveSocket("/live", Socket, {
          hooks: {
            EmailBuilder: EmailBuilderHook,
          }
        });

    """

    use Phoenix.LiveComponent

    alias VisualMailer.Renderer

    @impl true
    def mount(socket) do
      {:ok,
       socket
       |> assign(:preview_html, nil)
       |> assign(:saving, false)
       |> assign(:error, nil)}
    end

    @impl true
    def update(assigns, socket) do
      socket =
        socket
        |> assign(assigns)
        |> assign_new(:template, fn -> nil end)
        |> assign_new(:config, fn -> %{} end)
        |> assign_new(:variables, fn -> [] end)
        |> assign_new(:on_save, fn -> nil end)
        |> assign_new(:on_autosave, fn -> nil end)
        |> assign_new(:on_image_upload, fn -> nil end)

      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div
        id={@id}
        phx-hook="EmailBuilder"
        phx-target={@myself}
        data-template={encode_template(@template)}
        data-config={Jason.encode!(@config)}
        data-variables={Jason.encode!(@variables)}
        class="visual-mailer-builder h-full min-h-[600px]"
      >
        <div class="email-builder-loading flex items-center justify-center h-64 bg-gray-50 rounded-lg">
          <div class="text-center">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
            <span class="text-gray-600 text-sm">Loading email editor...</span>
          </div>
        </div>
        <%= if @error do %>
          <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            <%= @error %>
          </div>
        <% end %>
      </div>
      """
    end

    @impl true
    def handle_event("email_builder:save", %{"json" => json, "mjml" => mjml}, socket) do
      socket = assign(socket, :saving, true)

      # Render HTML on server (fast Rust NIF)
      case Renderer.MjmlCompiler.compile(mjml) do
        {:ok, html} ->
          template_data = %{
            content_json: json,
            mjml_cache: mjml,
            html_cache: html
          }

          notify_callback(socket.assigns.on_save, {:template_saved, template_data})

          {:noreply, assign(socket, saving: false, error: nil)}

        {:error, errors} ->
          notify_callback(socket.assigns.on_save, {:save_error, errors})

          {:noreply, assign(socket, saving: false, error: "Failed to compile template")}
      end
    end

    @impl true
    def handle_event("email_builder:autosave", %{"json" => json}, socket) do
      notify_callback(socket.assigns.on_autosave, {:template_autosaved, %{content_json: json}})
      {:noreply, socket}
    end

    @impl true
    def handle_event("email_builder:preview", %{"mjml" => mjml}, socket) do
      case Renderer.MjmlCompiler.compile(mjml) do
        {:ok, html} ->
          socket =
            socket
            |> assign(:preview_html, html)
            |> push_event("email_builder:preview_html", %{html: html})

          {:noreply, socket}

        {:error, _} ->
          {:noreply, socket}
      end
    end

    @impl true
    def handle_event(
          "email_builder:upload",
          %{"name" => name, "type" => type, "data" => data},
          socket
        ) do
      if upload_handler = socket.assigns.on_image_upload do
        case upload_handler.(%{name: name, type: type, data: data}) do
          {:ok, url} ->
            {:noreply, push_event(socket, "email_builder:upload_complete", %{url: url})}

          {:error, reason} ->
            {:noreply,
             push_event(socket, "email_builder:upload_error", %{error: inspect(reason)})}
        end
      else
        {:noreply,
         push_event(socket, "email_builder:upload_error", %{error: "Upload not configured"})}
      end
    end

    # Private functions

    defp encode_template(nil), do: "null"

    defp encode_template(%{content_json: json}) when is_map(json) do
      Jason.encode!(json)
    end

    defp encode_template(json) when is_map(json) do
      Jason.encode!(json)
    end

    defp encode_template(_), do: "null"

    defp notify_callback(nil, _message), do: :ok
    defp notify_callback(callback, message) when is_function(callback, 1), do: callback.(message)
  end
end
