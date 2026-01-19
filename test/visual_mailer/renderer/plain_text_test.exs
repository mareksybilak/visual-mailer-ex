defmodule VisualMailer.Renderer.PlainTextTest do
  use ExUnit.Case, async: true

  alias VisualMailer.Renderer.PlainText

  describe "convert/1" do
    test "strips HTML tags" do
      html = "<p>Hello <strong>World</strong>!</p>"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Hello"
      assert text =~ "World"
      refute text =~ "<p>"
      refute text =~ "<strong>"
    end

    test "converts links to text with URL" do
      html = ~s(<a href="https://example.com">Click here</a>)

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Click here"
      assert text =~ "(https://example.com)"
    end

    test "converts paragraphs to double newlines" do
      html = "<p>First paragraph</p><p>Second paragraph</p>"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "First paragraph"
      assert text =~ "Second paragraph"
      # Should have separation between paragraphs
      assert String.contains?(text, "\n")
    end

    test "converts br tags to newlines" do
      html = "Line 1<br>Line 2<br/>Line 3"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Line 1\nLine 2\nLine 3"
    end

    test "removes style and script tags with content" do
      html = """
      <html>
        <head>
          <style>.foo { color: red; }</style>
        </head>
        <body>
          <script>alert('xss');</script>
          <p>Visible content</p>
        </body>
      </html>
      """

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Visible content"
      refute text =~ "color: red"
      refute text =~ "alert"
    end

    test "removes HTML comments" do
      html = "<!-- This is a comment -->Visible content"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Visible content"
      refute text =~ "comment"
    end

    test "decodes HTML entities" do
      # Note: leading &nbsp; gets trimmed in plain text normalization
      # so we put content before and after it
      html = "Hello&nbsp;World&amp;&lt;&gt;&quot;&#039;"

      assert {:ok, text} = PlainText.convert(html)
      # NBSP (U+00A0) is preserved between words
      assert text =~ "Hello\u00A0World"
      assert text =~ "&"
      assert text =~ "<"
      assert text =~ ">"
      assert text =~ "\""
      assert text =~ "'"
    end

    test "normalizes whitespace" do
      html = "Multiple   spaces   here"

      assert {:ok, text} = PlainText.convert(html)
      # Multiple spaces should be reduced
      refute text =~ "   "
    end

    test "handles empty input" do
      assert {:ok, ""} = PlainText.convert("")
    end

    test "trims leading and trailing whitespace" do
      html = "   <p>Content</p>   "

      assert {:ok, text} = PlainText.convert(html)
      refute String.starts_with?(text, " ")
      refute String.ends_with?(text, " ")
    end

    test "converts lists to bullet points" do
      html = "<ul><li>Item 1</li><li>Item 2</li></ul>"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "- Item 1"
      assert text =~ "- Item 2"
    end

    test "converts table cells to tabs" do
      html = "<table><tr><td>Cell 1</td><td>Cell 2</td></tr></table>"

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Cell 1"
      assert text =~ "Cell 2"
    end

    test "handles complex email HTML" do
      html = """
      <html>
        <head><style>body { font-family: Arial; }</style></head>
        <body>
          <table>
            <tr>
              <td>
                <h1>Welcome!</h1>
                <p>Dear John,</p>
                <p>Thank you for signing up.</p>
                <a href="https://example.com/verify">Verify your email</a>
              </td>
            </tr>
          </table>
        </body>
      </html>
      """

      assert {:ok, text} = PlainText.convert(html)
      assert text =~ "Welcome!"
      assert text =~ "Dear John"
      assert text =~ "Thank you for signing up"
      assert text =~ "Verify your email"
      assert text =~ "(https://example.com/verify)"
      refute text =~ "font-family"
    end
  end
end
