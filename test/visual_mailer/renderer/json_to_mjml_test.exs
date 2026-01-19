defmodule VisualMailer.Renderer.JsonToMjmlTest do
  use ExUnit.Case, async: true

  alias VisualMailer.Renderer.JsonToMjml

  defp create_template(content \\ []) do
    %{
      "version" => "1.0",
      "metadata" => %{
        "subject" => "Test Subject",
        "preheader" => "Test Preheader"
      },
      "settings" => %{
        "backgroundColor" => "#f4f4f4",
        "contentWidth" => 600,
        "fontFamily" => "Arial, Helvetica, sans-serif"
      },
      "content" => content
    }
  end

  describe "convert/1" do
    test "generates valid MJML structure" do
      template = create_template()

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mjml>"
      assert mjml =~ "</mjml>"
      assert mjml =~ "<mj-head>"
      assert mjml =~ "<mj-body"
    end

    test "includes metadata in head" do
      template = create_template()

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-title>Test Subject</mj-title>"
      assert mjml =~ "<mj-preview>Test Preheader</mj-preview>"
    end

    test "applies content width to body" do
      template = create_template()

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ ~s(width="600px")
    end

    test "returns error for invalid template" do
      assert {:error, :invalid_template} = JsonToMjml.convert(%{"invalid" => "template"})
      assert {:error, :invalid_template} = JsonToMjml.convert(nil)
      assert {:error, :invalid_template} = JsonToMjml.convert("string")
    end
  end

  describe "EmailText block" do
    test "converts text block to mj-text" do
      template =
        create_template([
          %{
            "type" => "EmailText",
            "props" => %{
              "content" => "Hello World",
              "fontSize" => 16,
              "fontFamily" => "Arial, sans-serif",
              "color" => "#333333",
              "align" => "left",
              "lineHeight" => "1.5",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-text"
      assert mjml =~ "Hello World"
      assert mjml =~ ~s(font-size="16px")
      assert mjml =~ ~s(color="#333333")
      assert mjml =~ ~s(align="left")
    end
  end

  describe "EmailButton block" do
    test "converts button block to mj-button" do
      template =
        create_template([
          %{
            "type" => "EmailButton",
            "props" => %{
              "text" => "Click Me",
              "href" => "https://example.com",
              "backgroundColor" => "#007bff",
              "textColor" => "#ffffff",
              "fontSize" => 16,
              "borderRadius" => 4,
              "align" => "center",
              "fullWidth" => false,
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-button"
      assert mjml =~ "Click Me"
      assert mjml =~ ~s(href="https://example.com")
      assert mjml =~ ~s(background-color="#007bff")
      assert mjml =~ ~s(border-radius="4px")
    end

    test "handles full width button" do
      template =
        create_template([
          %{
            "type" => "EmailButton",
            "props" => %{
              "text" => "Full Width",
              "href" => "#",
              "backgroundColor" => "#007bff",
              "textColor" => "#ffffff",
              "fontSize" => 16,
              "borderRadius" => 4,
              "align" => "center",
              "fullWidth" => true,
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ ~s(width="100%")
    end
  end

  describe "EmailImage block" do
    test "converts image block to mj-image" do
      template =
        create_template([
          %{
            "type" => "EmailImage",
            "props" => %{
              "src" => "https://example.com/image.jpg",
              "alt" => "Test Image",
              "width" => 300,
              "align" => "center",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-image"
      assert mjml =~ ~s(src="https://example.com/image.jpg")
      assert mjml =~ ~s(alt="Test Image")
      assert mjml =~ ~s(width="300px")
    end

    test "handles full width image (width = 0)" do
      template =
        create_template([
          %{
            "type" => "EmailImage",
            "props" => %{
              "src" => "https://example.com/image.jpg",
              "alt" => "Full Width",
              "width" => 0,
              "align" => "center",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ ~s(width="100%")
    end

    test "includes href when provided" do
      template =
        create_template([
          %{
            "type" => "EmailImage",
            "props" => %{
              "src" => "https://example.com/image.jpg",
              "alt" => "Clickable",
              "width" => 300,
              "align" => "center",
              "href" => "https://example.com",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ ~s(href="https://example.com")
    end
  end

  describe "EmailHeader block" do
    test "converts header block to mj-section with mj-image" do
      template =
        create_template([
          %{
            "type" => "EmailHeader",
            "props" => %{
              "logoUrl" => "https://example.com/logo.png",
              "logoAlt" => "Company Logo",
              "logoWidth" => 150,
              "backgroundColor" => "#ffffff",
              "align" => "center",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-section"
      assert mjml =~ ~s(background-color="#ffffff")
      assert mjml =~ ~s(src="https://example.com/logo.png")
      assert mjml =~ ~s(alt="Company Logo")
      assert mjml =~ ~s(width="150px")
    end
  end

  describe "EmailSpacer block" do
    test "converts spacer block to mj-spacer" do
      template =
        create_template([
          %{
            "type" => "EmailSpacer",
            "props" => %{
              "height" => 30
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-spacer"
      assert mjml =~ ~s(height="30px")
    end
  end

  describe "EmailDivider block" do
    test "converts divider block to mj-divider" do
      template =
        create_template([
          %{
            "type" => "EmailDivider",
            "props" => %{
              "color" => "#e0e0e0",
              "width" => 1,
              "style" => "solid",
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mj-divider"
      assert mjml =~ ~s(border-color="#e0e0e0")
      assert mjml =~ ~s(border-width="1px")
      assert mjml =~ ~s(border-style="solid")
    end
  end

  describe "EmailFooter block" do
    test "converts footer block with unsubscribe link" do
      template =
        create_template([
          %{
            "type" => "EmailFooter",
            "props" => %{
              "companyName" => "ACME Corp",
              "address" => "123 Main St",
              "showUnsubscribe" => true,
              "unsubscribeText" => "Unsubscribe",
              "backgroundColor" => "#f4f4f4",
              "textColor" => "#666666"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "ACME Corp"
      assert mjml =~ "123 Main St"
      assert mjml =~ "{{unsubscribe_url}}"
      assert mjml =~ "Unsubscribe"
    end

    test "hides unsubscribe when disabled" do
      template =
        create_template([
          %{
            "type" => "EmailFooter",
            "props" => %{
              "companyName" => "ACME Corp",
              "address" => "123 Main St",
              "showUnsubscribe" => false,
              "unsubscribeText" => "Unsubscribe",
              "backgroundColor" => "#f4f4f4",
              "textColor" => "#666666"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      refute mjml =~ "{{unsubscribe_url}}"
    end
  end

  describe "HTML escaping" do
    test "escapes HTML special characters in subject" do
      template = %{
        create_template()
        | "metadata" => %{
            "subject" => "<script>alert(\"xss\")</script>",
            "preheader" => "Test"
          }
      }

      assert {:ok, mjml} = JsonToMjml.convert(template)
      refute mjml =~ "<script>"
      assert mjml =~ "&lt;script&gt;"
    end

    test "escapes HTML in button text" do
      template =
        create_template([
          %{
            "type" => "EmailButton",
            "props" => %{
              "text" => "<b>Bold</b>",
              "href" => "https://example.com?foo=1&bar=2",
              "backgroundColor" => "#007bff",
              "textColor" => "#ffffff",
              "fontSize" => 16,
              "borderRadius" => 4,
              "align" => "center",
              "fullWidth" => false,
              "padding" => "md"
            }
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "&lt;b&gt;Bold&lt;/b&gt;"
      assert mjml =~ "foo=1&amp;bar=2"
    end
  end

  describe "unknown blocks" do
    test "ignores unknown block types gracefully" do
      template =
        create_template([
          %{
            "type" => "UnknownBlock",
            "props" => %{"foo" => "bar"}
          }
        ])

      assert {:ok, mjml} = JsonToMjml.convert(template)
      assert mjml =~ "<mjml>"
      refute mjml =~ "UnknownBlock"
    end
  end
end
