defmodule VisualMailer do
  @moduledoc """
  Email template builder and renderer for Phoenix applications.

  VisualMailer provides:

  - **MJML Rendering** - Convert email templates to HTML using fast Rust NIF
  - **Ecto Schemas** - Store and manage email templates
  - **LiveView Components** - Integrate the visual editor in Phoenix apps
  - **Swoosh Integration** - Send emails via your configured mailer

  ## Installation

  Add to your `mix.exs`:

      def deps do
        [
          {:visual_mailer, "~> #{Mix.Project.config()[:version]}"}
        ]
      end

  Run the installer:

      mix visual_mailer.install

  ## Quick Start

  ### Rendering a template

      # Template JSON from the visual-mailer NPM editor
      template_json = %{
        "version" => "1.0",
        "metadata" => %{"subject" => "Welcome!", "preheader" => "..."},
        "settings" => %{"backgroundColor" => "#f4f4f4", "contentWidth" => 600},
        "content" => [
          %{"type" => "EmailText", "props" => %{"content" => "Hello {{name}}!"}}
        ]
      }

      # Render with variable interpolation
      {:ok, result} = VisualMailer.render(template_json, variables: %{"name" => "John"})

      # result contains:
      # - result.html - Rendered HTML ready to send
      # - result.plain_text - Plain text version
      # - result.mjml - Intermediate MJML (useful for debugging)

  ### Using with LiveView

      # In your LiveView template
      <.live_component
        module={VisualMailer.BuilderComponent}
        id="email-builder"
        template={@template}
        config={%{brand_color: "#007bff"}}
        on_save={fn data -> send(self(), {:template_saved, data}) end}
      />

  ### Sending emails

      # Build the email
      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to("user@example.com")
        |> Swoosh.Email.from("noreply@yourapp.com")
        |> Swoosh.Email.subject("Welcome!")

      # Send with rendered template
      VisualMailer.send(email, template_json,
        variables: %{"name" => "John"},
        mailer: MyApp.Mailer
      )

  ## Configuration

  Add to your `config/config.exs`:

      config :visual_mailer,
        repo: MyApp.Repo,           # Optional: for Ecto schemas
        mailer: MyApp.Mailer,       # Optional: for email sending
        oban_queue: :email_campaigns # Optional: for campaign workers
  """

  alias VisualMailer.Renderer

  @type render_result :: %{
          html: String.t(),
          plain_text: String.t(),
          mjml: String.t()
        }

  @doc """
  Render an email template JSON to HTML.

  ## Options

    * `:variables` - Map of variables to interpolate (e.g., `%{"name" => "John"}`)

  ## Examples

      iex> template = %{"version" => "1.0", "content" => [...]}
      iex> {:ok, result} = VisualMailer.render(template)
      iex> String.contains?(result.html, "<html")
      true

      iex> template = %{"version" => "1.0", "content" => [
      ...>   %{"type" => "EmailText", "props" => %{"content" => "Hello {{name}}!"}}
      ...> ]}
      iex> {:ok, result} = VisualMailer.render(template, variables: %{"name" => "John"})
      iex> String.contains?(result.html, "Hello John!")
      true

  """
  @spec render(map() | String.t(), keyword()) :: {:ok, render_result()} | {:error, term()}
  def render(template_json, opts \\ []) when is_map(template_json) or is_binary(template_json) do
    variables = Keyword.get(opts, :variables, %{})

    template =
      if is_binary(template_json) do
        Jason.decode!(template_json)
      else
        template_json
      end

    Renderer.render(template, variables)
  end

  @doc """
  Render an email template, raising on error.

  Same as `render/2` but raises `VisualMailer.RenderError` on failure.
  """
  @spec render!(map() | String.t(), keyword()) :: render_result()
  def render!(template_json, opts \\ []) do
    case render(template_json, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise VisualMailer.RenderError, reason: reason
    end
  end

  @doc """
  Send an email using a rendered template.

  ## Options

    * `:variables` - Map of variables to interpolate
    * `:mailer` - The Swoosh mailer module to use (required)

  ## Examples

      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to("user@example.com")
        |> Swoosh.Email.from("noreply@app.com")
        |> Swoosh.Email.subject("Welcome!")

      VisualMailer.send(email, template_json,
        variables: %{"name" => "John"},
        mailer: MyApp.Mailer
      )

  """
  @spec send(Swoosh.Email.t(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def send(%Swoosh.Email{} = email, template_json, opts) do
    with {:ok, rendered} <- render(template_json, opts) do
      mailer = Keyword.fetch!(opts, :mailer)

      email
      |> Swoosh.Email.html_body(rendered.html)
      |> Swoosh.Email.text_body(rendered.plain_text)
      |> mailer.deliver()
    end
  end

  @doc """
  Validate a template JSON structure.

  Returns `:ok` if valid, or `{:error, errors}` with a list of validation errors.

  ## Examples

      iex> VisualMailer.validate(%{"version" => "1.0", "content" => []})
      :ok

      iex> VisualMailer.validate(%{"invalid" => "template"})
      {:error, ["Missing or invalid version", ...]}

  """
  @spec validate(map()) :: :ok | {:error, [String.t()]}
  def validate(template_json) when is_map(template_json) do
    VisualMailer.Validator.validate(template_json)
  end
end

defmodule VisualMailer.RenderError do
  @moduledoc """
  Exception raised when template rendering fails.
  """
  defexception [:reason]

  @impl true
  def message(%{reason: reason}) do
    "Failed to render email template: #{inspect(reason)}"
  end
end
