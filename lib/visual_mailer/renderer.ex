defmodule VisualMailer.Renderer do
  @moduledoc """
  Main renderer module that orchestrates the email rendering pipeline.

  The rendering pipeline:

  1. **JSON → MJML** - Convert template JSON to MJML markup
  2. **Variable interpolation** - Replace `{{variable}}` placeholders
  3. **MJML → HTML** - Compile MJML to email-safe HTML (via Rust NIF)
  4. **HTML → Plain text** - Generate plain text version

  ## Performance

  MJML compilation uses a Rust NIF (via the `mjml` hex package) which is
  approximately 10x faster than Node.js-based solutions.
  """

  alias VisualMailer.Renderer.{JsonToMjml, MjmlCompiler, Variables, PlainText}

  @type render_result :: %{
          html: String.t(),
          plain_text: String.t(),
          mjml: String.t()
        }

  @doc """
  Render a template JSON to HTML with variable interpolation.

  ## Parameters

    * `template` - The template JSON map
    * `variables` - Map of variables to interpolate

  ## Returns

    * `{:ok, %{html: html, plain_text: plain_text, mjml: mjml}}`
    * `{:error, reason}`

  ## Examples

      iex> template = %{"version" => "1.0", "content" => [...]}
      iex> {:ok, result} = VisualMailer.Renderer.render(template, %{})
      iex> is_binary(result.html)
      true

  """
  @spec render(map(), map()) :: {:ok, render_result()} | {:error, term()}
  def render(template, variables \\ %{}) when is_map(template) and is_map(variables) do
    with {:ok, mjml} <- JsonToMjml.convert(template),
         {:ok, mjml_interpolated} <- Variables.interpolate(mjml, variables),
         {:ok, html} <- MjmlCompiler.compile(mjml_interpolated),
         {:ok, plain_text} <- PlainText.convert(html) do
      {:ok,
       %{
         html: html,
         plain_text: plain_text,
         mjml: mjml_interpolated
       }}
    end
  end
end
