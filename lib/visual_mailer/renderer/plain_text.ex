defmodule VisualMailer.Renderer.PlainText do
  @moduledoc """
  Converts HTML email to plain text version.

  Email clients that don't support HTML (or when HTML is disabled)
  will display the plain text version instead. This module creates
  a readable plain text version from the HTML.

  ## Transformations

  - Links: `<a href="url">text</a>` → `text (url)`
  - Paragraphs: `</p>` → double newline
  - Line breaks: `<br>` → newline
  - Lists: `<li>` → `- item`
  - Headers: stripped but followed by newlines
  """

  @doc """
  Convert HTML to plain text.

  ## Examples

      iex> html = "<p>Hello <a href='https://example.com'>World</a>!</p>"
      iex> {:ok, text} = PlainText.convert(html)
      iex> text
      "Hello World (https://example.com)!"

  """
  @spec convert(String.t()) :: {:ok, String.t()}
  def convert(html) when is_binary(html) do
    plain_text =
      html
      |> remove_html_comments()
      |> remove_style_and_script()
      |> convert_links()
      |> convert_lists()
      |> convert_paragraphs()
      |> convert_line_breaks()
      |> convert_headers()
      |> strip_tags()
      |> decode_entities()
      |> normalize_whitespace()
      |> String.trim()

    {:ok, plain_text}
  end

  # Private functions

  defp remove_html_comments(html) do
    Regex.replace(~r/<!--.*?-->/s, html, "")
  end

  defp remove_style_and_script(html) do
    html
    |> then(&Regex.replace(~r/<style[^>]*>.*?<\/style>/is, &1, ""))
    |> then(&Regex.replace(~r/<script[^>]*>.*?<\/script>/is, &1, ""))
    |> then(&Regex.replace(~r/<head[^>]*>.*?<\/head>/is, &1, ""))
  end

  defp convert_links(html) do
    Regex.replace(~r/<a[^>]*href=["']([^"']*?)["'][^>]*>([^<]*)<\/a>/i, html, fn _, url, text ->
      if String.trim(text) == "" do
        url
      else
        "#{text} (#{url})"
      end
    end)
  end

  defp convert_lists(html) do
    html
    |> Regex.replace(~r/<ul[^>]*>/i, "\n")
    |> Regex.replace(~r/<\/ul>/i, "\n")
    |> Regex.replace(~r/<ol[^>]*>/i, "\n")
    |> Regex.replace(~r/<\/ol>/i, "\n")
    |> Regex.replace(~r/<li[^>]*>/i, "\n- ")
    |> Regex.replace(~r/<\/li>/i, "")
  end

  defp convert_paragraphs(html) do
    html
    |> Regex.replace(~r/<\/p>/i, "\n\n")
    |> Regex.replace(~r/<\/div>/i, "\n")
    |> Regex.replace(~r/<\/td>/i, "\t")
    |> Regex.replace(~r/<\/tr>/i, "\n")
  end

  defp convert_line_breaks(html) do
    Regex.replace(~r/<br\s*\/?>/i, html, "\n")
  end

  defp convert_headers(html) do
    Regex.replace(~r/<\/h[1-6]>/i, html, "\n\n")
  end

  defp strip_tags(html) do
    Regex.replace(~r/<[^>]+>/, html, "")
  end

  defp decode_entities(text) do
    text
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#039;", "'")
    |> String.replace("&#39;", "'")
    |> String.replace("&apos;", "'")
    |> String.replace("&mdash;", "—")
    |> String.replace("&ndash;", "–")
    |> String.replace("&bull;", "•")
    |> String.replace("&copy;", "©")
    |> String.replace("&reg;", "®")
    |> String.replace("&trade;", "™")
    # Decode numeric entities
    |> decode_numeric_entities()
  end

  defp decode_numeric_entities(text) do
    Regex.replace(~r/&#(\d+);/, text, fn _, code ->
      code
      |> String.to_integer()
      |> then(&<<&1::utf8>>)
    end)
  end

  defp normalize_whitespace(text) do
    text
    # Replace multiple spaces with single space
    |> String.replace(~r/[ \t]+/, " ")
    # Replace 3+ newlines with double newline
    |> String.replace(~r/\n{3,}/, "\n\n")
    # Trim whitespace from each line
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.join("\n")
  end
end
