defmodule VisualMailer.Renderer.Variables do
  @moduledoc """
  Interpolates variables in email content.

  Supports:
  - `{{variable_name}}` - Simple interpolation
  - `{{variable_name|default:value}}` - With default value

  ## Examples

      iex> Variables.interpolate("Hello {{name}}!", %{"name" => "John"})
      {:ok, "Hello John!"}

      iex> Variables.interpolate("Hello {{name|default:Guest}}!", %{})
      {:ok, "Hello Guest!"}

  """

  @variable_pattern ~r/\{\{([a-z_][a-z0-9_]*)\}\}/i
  @variable_with_default ~r/\{\{([a-z_][a-z0-9_]*)\|default:([^}]*)\}\}/i

  @doc """
  Interpolate variables in content.

  ## Parameters

    * `content` - String containing `{{variable}}` placeholders
    * `variables` - Map of variable name to value

  ## Returns

    * `{:ok, interpolated_string}` - All variables replaced
    * `{:error, {:missing_variable, name}}` - Required variable not provided

  ## Examples

      iex> interpolate("Hello {{first_name}}!", %{"first_name" => "Jan"})
      {:ok, "Hello Jan!"}

      iex> interpolate("Hello {{first_name|default:Guest}}!", %{})
      {:ok, "Hello Guest!"}

      iex> interpolate("Hello {{first_name}}!", %{})
      {:error, {:missing_variable, "first_name"}}

  """
  @spec interpolate(String.t(), map()) :: {:ok, String.t()} | {:error, term()}
  def interpolate(content, variables) when is_binary(content) and is_map(variables) do
    # Convert all variable keys to strings for consistent lookup
    string_variables =
      variables
      |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end)
      |> Map.new()

    result =
      content
      |> replace_with_defaults(string_variables)
      |> replace_simple(string_variables)

    # Check for remaining uninterpolated variables
    case Regex.run(@variable_pattern, result) do
      nil ->
        {:ok, result}

      [_, var_name] ->
        {:error, {:missing_variable, var_name}}
    end
  end

  @doc """
  Interpolate variables, raising on missing variables.
  """
  @spec interpolate!(String.t(), map()) :: String.t()
  def interpolate!(content, variables) do
    case interpolate(content, variables) do
      {:ok, result} -> result
      {:error, reason} -> raise "Variable interpolation failed: #{inspect(reason)}"
    end
  end

  @doc """
  Extract all variable names from content.

  ## Examples

      iex> extract_variables("Hello {{name}}, your order {{order_id}} is ready!")
      ["name", "order_id"]

  """
  @spec extract_variables(String.t()) :: [String.t()]
  def extract_variables(content) when is_binary(content) do
    simple =
      @variable_pattern
      |> Regex.scan(content)
      |> Enum.map(fn [_, name] -> name end)

    with_defaults =
      @variable_with_default
      |> Regex.scan(content)
      |> Enum.map(fn [_, name, _default] -> name end)

    (simple ++ with_defaults)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Private functions

  defp replace_with_defaults(content, variables) do
    Regex.replace(@variable_with_default, content, fn _, var_name, default ->
      Map.get(variables, var_name, default)
    end)
  end

  defp replace_simple(content, variables) do
    Regex.replace(@variable_pattern, content, fn full_match, var_name ->
      Map.get(variables, var_name, full_match)
    end)
  end
end
