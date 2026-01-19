defmodule VisualMailer.Renderer.VariablesTest do
  use ExUnit.Case, async: true

  alias VisualMailer.Renderer.Variables

  describe "interpolate/2" do
    test "replaces simple variables" do
      content = "Hello {{first_name}}!"
      variables = %{"first_name" => "Jan"}

      assert {:ok, "Hello Jan!"} = Variables.interpolate(content, variables)
    end

    test "handles atom keys in variables" do
      content = "Hello {{first_name}}!"
      variables = %{first_name: "Jan"}

      assert {:ok, "Hello Jan!"} = Variables.interpolate(content, variables)
    end

    test "uses default value when variable missing" do
      content = "Hello {{first_name|default:Guest}}!"
      variables = %{}

      assert {:ok, "Hello Guest!"} = Variables.interpolate(content, variables)
    end

    test "prefers provided value over default" do
      content = "Hello {{first_name|default:Guest}}!"
      variables = %{"first_name" => "Jan"}

      assert {:ok, "Hello Jan!"} = Variables.interpolate(content, variables)
    end

    test "returns error for missing required variable" do
      content = "Hello {{first_name}}!"
      variables = %{}

      assert {:error, {:missing_variable, "first_name"}} =
               Variables.interpolate(content, variables)
    end

    test "handles multiple variables" do
      content = "{{greeting}} {{name}}, welcome to {{company}}!"

      variables = %{
        "greeting" => "Hi",
        "name" => "Jan",
        "company" => "ACME"
      }

      assert {:ok, "Hi Jan, welcome to ACME!"} = Variables.interpolate(content, variables)
    end

    test "handles variables with underscores" do
      content = "Order: {{order_id}}, Customer: {{customer_name}}"
      variables = %{"order_id" => "12345", "customer_name" => "Jan Kowalski"}

      assert {:ok, "Order: 12345, Customer: Jan Kowalski"} =
               Variables.interpolate(content, variables)
    end

    test "handles empty content" do
      assert {:ok, ""} = Variables.interpolate("", %{})
    end

    test "handles content with no variables" do
      content = "Hello World!"
      assert {:ok, "Hello World!"} = Variables.interpolate(content, %{})
    end
  end

  describe "extract_variables/1" do
    test "extracts simple variables" do
      content = "Hello {{name}}, your order {{order_id}} is ready!"
      assert Variables.extract_variables(content) == ["name", "order_id"]
    end

    test "extracts variables with defaults" do
      content = "Hello {{name|default:Guest}}, welcome!"
      assert Variables.extract_variables(content) == ["name"]
    end

    test "returns unique variables" do
      content = "{{name}} {{name}} {{name}}"
      assert Variables.extract_variables(content) == ["name"]
    end

    test "returns sorted variables" do
      content = "{{zebra}} {{apple}} {{mango}}"
      assert Variables.extract_variables(content) == ["apple", "mango", "zebra"]
    end

    test "returns empty list for no variables" do
      assert Variables.extract_variables("Hello World!") == []
    end
  end

  describe "interpolate!/2" do
    test "returns interpolated string on success" do
      assert Variables.interpolate!("Hello {{name}}!", %{"name" => "Jan"}) == "Hello Jan!"
    end

    test "raises on missing variable" do
      assert_raise RuntimeError, ~r/Variable interpolation failed/, fn ->
        Variables.interpolate!("Hello {{name}}!", %{})
      end
    end
  end
end
