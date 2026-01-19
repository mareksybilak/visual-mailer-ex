defmodule VisualMailer.Renderer.MjmlCompiler do
  @moduledoc """
  Compiles MJML markup to HTML using Rust NIF.

  This module uses the `mjml` hex package which provides a Rust NIF
  for MJML compilation. This is approximately 10x faster than Node.js
  based solutions and has zero external dependencies.

  ## Performance

  Typical compilation times:
  - Simple template (5 blocks): ~1-2ms
  - Medium template (20 blocks): ~3-5ms
  - Complex template (50+ blocks): ~10-15ms
  """

  @doc """
  Compile MJML markup to HTML.

  ## Examples

      iex> mjml = "<mjml><mj-body><mj-section><mj-column><mj-text>Hello</mj-text></mj-column></mj-section></mj-body></mjml>"
      iex> {:ok, html} = MjmlCompiler.compile(mjml)
      iex> String.contains?(html, "Hello")
      true

  ## Errors

  Returns `{:error, {:mjml_errors, errors}}` when MJML syntax is invalid.
  """
  @spec compile(String.t()) :: {:ok, String.t()} | {:error, term()}
  def compile(mjml) when is_binary(mjml) do
    case Mjml.to_html(mjml) do
      {:ok, html} ->
        {:ok, html}

      {:error, errors} when is_list(errors) ->
        {:error, {:mjml_errors, errors}}

      {:error, reason} ->
        {:error, {:mjml_error, reason}}
    end
  end

  @doc """
  Compile MJML markup to HTML, raising on error.
  """
  @spec compile!(String.t()) :: String.t()
  def compile!(mjml) do
    case compile(mjml) do
      {:ok, html} -> html
      {:error, reason} -> raise "MJML compilation failed: #{inspect(reason)}"
    end
  end
end
