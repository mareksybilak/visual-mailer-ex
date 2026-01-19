defmodule VisualMailerTest do
  use ExUnit.Case, async: true

  describe "validate/1" do
    test "delegates to Validator module" do
      template = %{
        "version" => "1.0",
        "metadata" => %{"subject" => "Test", "preheader" => "Preview"},
        "settings" => %{
          "backgroundColor" => "#fff",
          "contentWidth" => 600,
          "fontFamily" => "Arial"
        },
        "content" => []
      }

      assert :ok = VisualMailer.validate(template)
    end

    test "returns errors for invalid template" do
      assert {:error, _errors} = VisualMailer.validate(%{"invalid" => "template"})
    end
  end

  describe "render/2" do
    test "renders simple template" do
      template = %{
        "version" => "1.0",
        "metadata" => %{"subject" => "Test", "preheader" => "Preview"},
        "settings" => %{
          "backgroundColor" => "#ffffff",
          "contentWidth" => 600,
          "fontFamily" => "Arial, Helvetica, sans-serif"
        },
        "content" => [
          %{
            "type" => "EmailText",
            "props" => %{
              "content" => "Hello World",
              "fontSize" => 16,
              "fontFamily" => "Arial",
              "color" => "#333",
              "align" => "left",
              "lineHeight" => "1.5",
              "padding" => "md"
            }
          }
        ]
      }

      assert {:ok, result} = VisualMailer.render(template)
      assert is_binary(result.html)
      assert is_binary(result.plain_text)
      assert is_binary(result.mjml)
      assert result.html =~ "Hello World"
      assert result.plain_text =~ "Hello World"
    end

    test "interpolates variables" do
      template = %{
        "version" => "1.0",
        "metadata" => %{"subject" => "Test", "preheader" => "Preview"},
        "settings" => %{
          "backgroundColor" => "#ffffff",
          "contentWidth" => 600,
          "fontFamily" => "Arial, Helvetica, sans-serif"
        },
        "content" => [
          %{
            "type" => "EmailText",
            "props" => %{
              "content" => "Hello {{name}}!",
              "fontSize" => 16,
              "fontFamily" => "Arial",
              "color" => "#333",
              "align" => "left",
              "lineHeight" => "1.5",
              "padding" => "md"
            }
          }
        ]
      }

      assert {:ok, result} = VisualMailer.render(template, variables: %{"name" => "John"})
      assert result.html =~ "Hello John!"
      refute result.html =~ "{{name}}"
    end

    test "handles JSON string input" do
      template_json =
        Jason.encode!(%{
          "version" => "1.0",
          "metadata" => %{"subject" => "Test", "preheader" => "Preview"},
          "settings" => %{
            "backgroundColor" => "#ffffff",
            "contentWidth" => 600,
            "fontFamily" => "Arial, Helvetica, sans-serif"
          },
          "content" => []
        })

      assert {:ok, result} = VisualMailer.render(template_json)
      assert is_binary(result.html)
    end
  end

  describe "render!/2" do
    test "returns result on success" do
      template = %{
        "version" => "1.0",
        "metadata" => %{"subject" => "Test", "preheader" => "Preview"},
        "settings" => %{
          "backgroundColor" => "#ffffff",
          "contentWidth" => 600,
          "fontFamily" => "Arial, Helvetica, sans-serif"
        },
        "content" => []
      }

      result = VisualMailer.render!(template)
      assert is_binary(result.html)
    end

    test "raises on error" do
      assert_raise VisualMailer.RenderError, fn ->
        VisualMailer.render!(%{"invalid" => "template"})
      end
    end
  end
end
