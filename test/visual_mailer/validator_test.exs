defmodule VisualMailer.ValidatorTest do
  use ExUnit.Case, async: true

  alias VisualMailer.Validator

  defp create_valid_template do
    %{
      "version" => "1.0",
      "metadata" => %{
        "subject" => "Test Subject",
        "preheader" => "Test Preheader"
      },
      "settings" => %{
        "backgroundColor" => "#ffffff",
        "contentWidth" => 600,
        "fontFamily" => "Arial, Helvetica, sans-serif"
      },
      "content" => []
    }
  end

  describe "validate/1" do
    test "accepts valid template" do
      template = create_valid_template()
      assert :ok = Validator.validate(template)
    end

    test "rejects non-map template" do
      assert {:error, _} = Validator.validate("string")
      assert {:error, _} = Validator.validate(nil)
      assert {:error, _} = Validator.validate([])
    end
  end

  describe "version validation" do
    test "accepts version 1.0" do
      template = create_valid_template()
      assert :ok = Validator.validate(template)
    end

    test "rejects unsupported version" do
      template = %{create_valid_template() | "version" => "2.0"}
      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "version"))
    end

    test "rejects missing version" do
      template = Map.delete(create_valid_template(), "version")
      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "version"))
    end
  end

  describe "metadata validation" do
    test "accepts valid metadata" do
      template = create_valid_template()
      assert :ok = Validator.validate(template)
    end

    test "rejects invalid metadata type" do
      template = %{create_valid_template() | "metadata" => "invalid"}
      assert {:error, _} = Validator.validate(template)
    end
  end

  describe "settings validation" do
    test "accepts valid settings" do
      template = create_valid_template()
      assert :ok = Validator.validate(template)
    end

    test "rejects contentWidth too small" do
      template = put_in(create_valid_template(), ["settings", "contentWidth"], 300)
      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "contentWidth"))
    end

    test "rejects contentWidth too large" do
      template = put_in(create_valid_template(), ["settings", "contentWidth"], 800)
      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "contentWidth"))
    end

    test "accepts contentWidth within range" do
      template = put_in(create_valid_template(), ["settings", "contentWidth"], 550)
      assert :ok = Validator.validate(template)
    end
  end

  describe "content validation" do
    test "accepts empty content array" do
      template = create_valid_template()
      assert :ok = Validator.validate(template)
    end

    test "rejects non-array content" do
      template = %{create_valid_template() | "content" => "invalid"}
      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "content"))
    end

    test "rejects invalid block type" do
      template = %{
        create_valid_template()
        | "content" => [
            %{"type" => "InvalidBlock", "props" => %{}}
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "InvalidBlock"))
    end

    test "accepts valid EmailText block" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailText",
              "props" => %{
                "content" => "Hello",
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

      assert :ok = Validator.validate(template)
    end

    test "rejects invalid fontSize in EmailText" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailText",
              "props" => %{
                "content" => "Hello",
                "fontSize" => 99,
                "fontFamily" => "Arial",
                "color" => "#333",
                "align" => "left",
                "lineHeight" => "1.5",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "fontSize"))
    end
  end

  describe "EmailButton validation" do
    test "requires text property" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailButton",
              "props" => %{
                "href" => "https://example.com",
                "backgroundColor" => "#007bff",
                "textColor" => "#fff",
                "fontSize" => 16,
                "borderRadius" => 4,
                "align" => "center",
                "fullWidth" => false,
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "text"))
    end

    test "requires href property" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailButton",
              "props" => %{
                "text" => "Click",
                "backgroundColor" => "#007bff",
                "textColor" => "#fff",
                "fontSize" => 16,
                "borderRadius" => 4,
                "align" => "center",
                "fullWidth" => false,
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "href"))
    end

    test "rejects invalid borderRadius" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailButton",
              "props" => %{
                "text" => "Click",
                "href" => "https://example.com",
                "backgroundColor" => "#007bff",
                "textColor" => "#fff",
                "fontSize" => 16,
                "borderRadius" => 16,
                "align" => "center",
                "fullWidth" => false,
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "borderRadius"))
    end
  end

  describe "EmailImage validation" do
    test "requires alt text for accessibility" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailImage",
              "props" => %{
                "src" => "https://example.com/image.jpg",
                "width" => 300,
                "align" => "center",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "alt"))
    end

    test "accepts image with alt text" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailImage",
              "props" => %{
                "src" => "https://example.com/image.jpg",
                "alt" => "Description",
                "width" => 300,
                "align" => "center",
                "padding" => "md"
              }
            }
          ]
      }

      assert :ok = Validator.validate(template)
    end
  end

  describe "EmailSpacer validation" do
    test "accepts valid height" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailSpacer",
              "props" => %{"height" => 20}
            }
          ]
      }

      assert :ok = Validator.validate(template)
    end

    test "rejects invalid height" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailSpacer",
              "props" => %{"height" => 15}
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "height"))
    end
  end

  describe "EmailColumns validation" do
    test "accepts valid column count" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailColumns",
              "props" => %{
                "columns" => 2,
                "gap" => "md",
                "verticalAlign" => "top",
                "stackOnMobile" => true
              }
            }
          ]
      }

      assert :ok = Validator.validate(template)
    end

    test "rejects invalid column count" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailColumns",
              "props" => %{
                "columns" => 5,
                "gap" => "md",
                "verticalAlign" => "top",
                "stackOnMobile" => true
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "columns"))
    end
  end

  describe "EmailDivider validation" do
    test "accepts valid divider" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailDivider",
              "props" => %{
                "color" => "#e0e0e0",
                "width" => 1,
                "style" => "solid",
                "padding" => "md"
              }
            }
          ]
      }

      assert :ok = Validator.validate(template)
    end

    test "rejects invalid width" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailDivider",
              "props" => %{
                "color" => "#e0e0e0",
                "width" => 5,
                "style" => "solid",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "width"))
    end

    test "rejects invalid style" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailDivider",
              "props" => %{
                "color" => "#e0e0e0",
                "width" => 1,
                "style" => "wavy",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "style"))
    end
  end

  describe "EmailHeader validation" do
    test "accepts valid header" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailHeader",
              "props" => %{
                "logoUrl" => "https://example.com/logo.png",
                "logoAlt" => "Logo",
                "logoWidth" => 150,
                "backgroundColor" => "#fff",
                "align" => "center",
                "padding" => "md"
              }
            }
          ]
      }

      assert :ok = Validator.validate(template)
    end

    test "rejects logoWidth too small" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailHeader",
              "props" => %{
                "logoUrl" => "https://example.com/logo.png",
                "logoAlt" => "Logo",
                "logoWidth" => 30,
                "backgroundColor" => "#fff",
                "align" => "center",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "logoWidth"))
    end

    test "rejects logoWidth too large" do
      template = %{
        create_valid_template()
        | "content" => [
            %{
              "type" => "EmailHeader",
              "props" => %{
                "logoUrl" => "https://example.com/logo.png",
                "logoAlt" => "Logo",
                "logoWidth" => 400,
                "backgroundColor" => "#fff",
                "align" => "center",
                "padding" => "md"
              }
            }
          ]
      }

      assert {:error, errors} = Validator.validate(template)
      assert Enum.any?(errors, &String.contains?(&1, "logoWidth"))
    end
  end
end
