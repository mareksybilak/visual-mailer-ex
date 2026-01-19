defmodule VisualMailer.Renderer.JsonToMjml do
  @moduledoc """
  Converts email template JSON to MJML markup.

  This module transforms the visual editor's JSON output into MJML,
  the framework that ensures cross-client email compatibility.
  """

  @padding_map %{
    "none" => "0px",
    "xs" => "5px",
    "sm" => "10px",
    "md" => "20px",
    "lg" => "30px",
    "xl" => "40px"
  }

  @doc """
  Convert template JSON to MJML markup.

  ## Examples

      iex> template = %{
      ...>   "metadata" => %{"subject" => "Test"},
      ...>   "settings" => %{"contentWidth" => 600},
      ...>   "content" => []
      ...> }
      iex> {:ok, mjml} = JsonToMjml.convert(template)
      iex> String.contains?(mjml, "<mjml>")
      true

  """
  @spec convert(map()) :: {:ok, String.t()} | {:error, term()}
  def convert(%{"content" => blocks} = template) when is_list(blocks) do
    metadata = Map.get(template, "metadata", %{})
    settings = Map.get(template, "settings", %{})

    mjml = """
    <mjml>
      <mj-head>
        #{render_head(metadata, settings)}
      </mj-head>
      <mj-body width="#{settings["contentWidth"] || 600}px">
        #{render_blocks(blocks)}
      </mj-body>
    </mjml>
    """

    {:ok, mjml}
  end

  def convert(_), do: {:error, :invalid_template}

  # Private functions

  defp render_head(metadata, settings) do
    """
        <mj-title>#{escape_html(metadata["subject"] || "")}</mj-title>
        <mj-preview>#{escape_html(metadata["preheader"] || "")}</mj-preview>
        <mj-attributes>
          <mj-all font-family="#{settings["fontFamily"] || "Arial, Helvetica, sans-serif"}" />
          <mj-body background-color="#{settings["backgroundColor"] || "#ffffff"}" />
          <mj-section padding="0" />
        </mj-attributes>
    """
  end

  defp render_blocks(blocks) when is_list(blocks) do
    Enum.map_join(blocks, "\n", &render_block/1)
  end

  defp render_block(%{"type" => "EmailHeader", "props" => props}) do
    padding = get_padding(props["padding"])

    """
        <mj-section background-color="#{props["backgroundColor"] || "#ffffff"}" padding="#{padding}">
          <mj-column>
            <mj-image
              src="#{escape_html(props["logoUrl"] || "")}"
              alt="#{escape_html(props["logoAlt"] || "Logo")}"
              width="#{props["logoWidth"] || 150}px"
              align="#{props["align"] || "center"}"
            />
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailText", "props" => props}) do
    padding = get_padding(props["padding"])

    """
        <mj-section padding="#{padding}">
          <mj-column>
            <mj-text
              font-size="#{props["fontSize"] || 16}px"
              font-family="#{props["fontFamily"] || "Arial, Helvetica, sans-serif"}"
              color="#{props["color"] || "#333333"}"
              align="#{props["align"] || "left"}"
              line-height="#{props["lineHeight"] || "1.5"}"
            >#{props["content"] || ""}</mj-text>
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailImage", "props" => props}) do
    padding = get_padding(props["padding"])
    width = if props["width"] in [0, "full"], do: "100%", else: "#{props["width"]}px"
    href_attr = if props["href"], do: ~s(href="#{escape_html(props["href"])}"), else: ""

    """
        <mj-section padding="#{padding}">
          <mj-column>
            <mj-image
              src="#{escape_html(props["src"] || "")}"
              alt="#{escape_html(props["alt"] || "")}"
              width="#{width}"
              align="#{props["align"] || "center"}"
              #{href_attr}
            />
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailButton", "props" => props}) do
    button_padding =
      case props["padding"] do
        "sm" -> "10px 20px"
        "lg" -> "20px 40px"
        _ -> "15px 30px"
      end

    full_width = if props["fullWidth"], do: ~s(width="100%"), else: ""

    """
        <mj-section>
          <mj-column>
            <mj-button
              href="#{escape_html(props["href"] || "#")}"
              background-color="#{props["backgroundColor"] || "#007bff"}"
              color="#{props["textColor"] || "#ffffff"}"
              font-size="#{props["fontSize"] || 16}px"
              border-radius="#{props["borderRadius"] || 4}px"
              align="#{props["align"] || "center"}"
              padding="#{button_padding}"
              #{full_width}
            >#{escape_html(props["text"] || "Button")}</mj-button>
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailColumns", "props" => props} = block) do
    children = block["children"] || []
    columns = props["columns"] || 2
    vertical_align = props["verticalAlign"] || "top"
    stack_attr = if props["stackOnMobile"], do: "", else: ~s(mj-class="no-stack")

    column_content =
      if Enum.empty?(children) do
        # Empty columns
        Enum.map_join(1..columns, "\n", fn _ ->
          """
              <mj-column vertical-align="#{vertical_align}">
                <!-- Empty column -->
              </mj-column>
          """
        end)
      else
        # Distribute children into columns
        items_per_column = ceil(length(children) / columns)

        children
        |> Enum.chunk_every(items_per_column)
        |> Enum.map_join("\n", fn col_children ->
          col_content = render_blocks(col_children)

          """
              <mj-column vertical-align="#{vertical_align}">
                #{col_content}
              </mj-column>
          """
        end)
      end

    """
        <mj-section #{stack_attr}>
          #{column_content}
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailSpacer", "props" => props}) do
    """
        <mj-section>
          <mj-column>
            <mj-spacer height="#{props["height"] || 20}px" />
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailDivider", "props" => props}) do
    padding = get_padding(props["padding"])

    """
        <mj-section padding="#{padding}">
          <mj-column>
            <mj-divider
              border-color="#{props["color"] || "#e0e0e0"}"
              border-width="#{props["width"] || 1}px"
              border-style="#{props["style"] || "solid"}"
            />
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(%{"type" => "EmailSocial", "props" => props}) do
    networks = build_social_networks(props)

    if Enum.empty?(networks) do
      ""
    else
      mode = if props["iconStyle"] == "color", do: "vertical", else: props["iconStyle"]
      icon_size = props["iconSize"] || 32

      network_elements =
        Enum.map_join(networks, "\n", fn {type, url} ->
          ~s(          <mj-social-element name="#{type}" href="#{escape_html(url)}" icon-size="#{icon_size}px" />)
        end)

      """
          <mj-section>
            <mj-column>
              <mj-social align="#{props["align"] || "center"}" mode="#{mode}">
      #{network_elements}
              </mj-social>
            </mj-column>
          </mj-section>
      """
    end
  end

  defp render_block(%{"type" => "EmailFooter", "props" => props}) do
    unsubscribe_link =
      if props["showUnsubscribe"] do
        ~s(<br/><a href="{{unsubscribe_url}}" style="color: #{props["textColor"] || "#666666"}; text-decoration: underline;">#{escape_html(props["unsubscribeText"] || "Unsubscribe")}</a>)
      else
        ""
      end

    address = (props["address"] || "") |> escape_html() |> String.replace("\n", "<br/>")

    """
        <mj-section background-color="#{props["backgroundColor"] || "#f4f4f4"}">
          <mj-column>
            <mj-text
              font-size="12px"
              color="#{props["textColor"] || "#666666"}"
              align="center"
              line-height="1.6"
            >
              <strong>#{escape_html(props["companyName"] || "")}</strong><br/>
              #{address}
              #{unsubscribe_link}
            </mj-text>
          </mj-column>
        </mj-section>
    """
  end

  defp render_block(_unknown), do: ""

  defp build_social_networks(props) do
    [
      {"facebook", props["facebookUrl"]},
      {"twitter", props["twitterUrl"]},
      {"linkedin", props["linkedinUrl"]},
      {"instagram", props["instagramUrl"]},
      {"youtube", props["youtubeUrl"]}
    ]
    |> Enum.filter(fn {_type, url} -> url && url != "" end)
  end

  defp get_padding(key) when is_binary(key), do: @padding_map[key] || @padding_map["md"]
  defp get_padding(_), do: @padding_map["md"]

  defp escape_html(nil), do: ""

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#039;")
  end
end
