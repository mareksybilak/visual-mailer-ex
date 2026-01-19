defmodule VisualMailer.Validator do
  @moduledoc """
  Validates email template JSON structure.

  Ensures templates conform to the expected schema before rendering.
  """

  @valid_block_types ~w(
    EmailHeader EmailText EmailImage EmailButton
    EmailColumns EmailSpacer EmailDivider EmailSocial EmailFooter
  )

  @valid_padding ~w(none xs sm md lg xl)
  @valid_align ~w(left center right)
  @valid_font_sizes [12, 14, 16, 18, 20, 24, 28, 32, 36, 48]
  @valid_line_heights ~w(1.2 1.4 1.5 1.6 1.8)
  @valid_border_radius [0, 4, 8]
  @valid_spacer_heights [10, 20, 30, 40, 50, 60]
  @valid_divider_widths [1, 2, 3]
  @valid_column_counts [1, 2, 3, 4]

  @doc """
  Validate a template JSON structure.

  Returns `:ok` if valid, or `{:error, errors}` with a list of error messages.

  ## Examples

      iex> Validator.validate(%{"version" => "1.0", "content" => []})
      :ok

      iex> Validator.validate(%{})
      {:error, ["Missing or invalid version"]}

  """
  @spec validate(map()) :: :ok | {:error, [String.t()]}
  def validate(template) when is_map(template) do
    errors = []

    errors =
      errors
      |> validate_version(template)
      |> validate_metadata(template)
      |> validate_settings(template)
      |> validate_content(template)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, Enum.reverse(errors)}
    end
  end

  def validate(_), do: {:error, ["Template must be a map"]}

  # Private validators

  defp validate_version(errors, %{"version" => "1.0"}), do: errors
  defp validate_version(errors, %{"version" => v}), do: ["Unsupported version: #{v}" | errors]
  defp validate_version(errors, _), do: ["Missing or invalid version" | errors]

  defp validate_metadata(errors, %{"metadata" => meta}) when is_map(meta) do
    errors
    |> validate_string_field(meta, "subject", "metadata.subject")
    |> validate_string_field(meta, "preheader", "metadata.preheader")
  end

  defp validate_metadata(errors, _), do: ["Missing or invalid metadata" | errors]

  defp validate_settings(errors, %{"settings" => settings}) when is_map(settings) do
    errors
    |> validate_color_field(settings, "backgroundColor", "settings.backgroundColor")
    |> validate_content_width(settings)
    |> validate_string_field(settings, "fontFamily", "settings.fontFamily")
  end

  defp validate_settings(errors, _), do: ["Missing or invalid settings" | errors]

  defp validate_content(errors, %{"content" => content}) when is_list(content) do
    content
    |> Enum.with_index()
    |> Enum.reduce(errors, fn {block, index}, acc ->
      validate_block(acc, block, "content[#{index}]")
    end)
  end

  defp validate_content(errors, _), do: ["content must be an array" | errors]

  defp validate_block(errors, %{"type" => type, "props" => props} = block, prefix)
       when type in @valid_block_types and is_map(props) do
    errors
    |> validate_block_props(type, props, prefix)
    |> validate_block_children(block, prefix)
  end

  defp validate_block(errors, %{"type" => type}, prefix) when type not in @valid_block_types do
    ["#{prefix}: Invalid block type '#{type}'" | errors]
  end

  defp validate_block(errors, _, prefix) do
    ["#{prefix}: Block must have type and props" | errors]
  end

  defp validate_block_props(errors, "EmailHeader", props, prefix) do
    errors
    |> validate_number_range(props, "logoWidth", 50, 300, "#{prefix}.props.logoWidth")
    |> validate_enum(props, "align", @valid_align, "#{prefix}.props.align")
    |> validate_enum(props, "padding", @valid_padding, "#{prefix}.props.padding")
  end

  defp validate_block_props(errors, "EmailText", props, prefix) do
    errors
    |> validate_enum(props, "fontSize", @valid_font_sizes, "#{prefix}.props.fontSize")
    |> validate_enum(props, "lineHeight", @valid_line_heights, "#{prefix}.props.lineHeight")
    |> validate_enum(props, "align", @valid_align, "#{prefix}.props.align")
    |> validate_enum(props, "padding", @valid_padding, "#{prefix}.props.padding")
  end

  defp validate_block_props(errors, "EmailImage", props, prefix) do
    if props["alt"] in [nil, ""] do
      ["#{prefix}.props.alt is required for accessibility" | errors]
    else
      errors
    end
    |> validate_enum(props, "align", @valid_align, "#{prefix}.props.align")
    |> validate_enum(props, "padding", @valid_padding, "#{prefix}.props.padding")
  end

  defp validate_block_props(errors, "EmailButton", props, prefix) do
    errors
    |> validate_required(props, "text", "#{prefix}.props.text")
    |> validate_required(props, "href", "#{prefix}.props.href")
    |> validate_enum(props, "borderRadius", @valid_border_radius, "#{prefix}.props.borderRadius")
    |> validate_enum(props, "align", @valid_align, "#{prefix}.props.align")
  end

  defp validate_block_props(errors, "EmailColumns", props, prefix) do
    validate_enum(errors, props, "columns", @valid_column_counts, "#{prefix}.props.columns")
  end

  defp validate_block_props(errors, "EmailSpacer", props, prefix) do
    validate_enum(errors, props, "height", @valid_spacer_heights, "#{prefix}.props.height")
  end

  defp validate_block_props(errors, "EmailDivider", props, prefix) do
    errors
    |> validate_enum(props, "width", @valid_divider_widths, "#{prefix}.props.width")
    |> validate_enum(props, "style", ~w(solid dashed dotted), "#{prefix}.props.style")
    |> validate_enum(props, "padding", @valid_padding, "#{prefix}.props.padding")
  end

  defp validate_block_props(errors, _type, _props, _prefix), do: errors

  defp validate_block_children(errors, %{"type" => "EmailColumns", "children" => children}, prefix)
       when is_list(children) do
    children
    |> Enum.with_index()
    |> Enum.reduce(errors, fn {child, index}, acc ->
      validate_block(acc, child, "#{prefix}.children[#{index}]")
    end)
  end

  defp validate_block_children(errors, _, _), do: errors

  # Helper validators

  defp validate_string_field(errors, map, key, field_name) do
    case Map.get(map, key) do
      nil -> errors
      value when is_binary(value) -> errors
      _ -> ["#{field_name} must be a string" | errors]
    end
  end

  defp validate_color_field(errors, map, key, field_name) do
    case Map.get(map, key) do
      nil -> errors
      value when is_binary(value) -> errors
      _ -> ["#{field_name} must be a color string" | errors]
    end
  end

  defp validate_content_width(errors, settings) do
    case settings["contentWidth"] do
      nil ->
        errors

      width when is_integer(width) and width >= 400 and width <= 700 ->
        errors

      width when is_integer(width) ->
        ["settings.contentWidth must be between 400 and 700" | errors]

      _ ->
        ["settings.contentWidth must be a number" | errors]
    end
  end

  defp validate_number_range(errors, map, key, min, max, field_name) do
    case Map.get(map, key) do
      nil -> errors
      value when is_number(value) and value >= min and value <= max -> errors
      value when is_number(value) -> ["#{field_name} must be between #{min} and #{max}" | errors]
      _ -> ["#{field_name} must be a number" | errors]
    end
  end

  defp validate_enum(errors, map, key, valid_values, field_name) do
    case Map.get(map, key) do
      nil ->
        errors

      value ->
        if Enum.member?(valid_values, value) do
          errors
        else
          ["#{field_name} must be one of: #{Enum.join(valid_values, ", ")} (got: #{inspect(value)})" | errors]
        end
    end
  end

  defp validate_required(errors, map, key, field_name) do
    case Map.get(map, key) do
      nil -> ["#{field_name} is required" | errors]
      "" -> ["#{field_name} is required" | errors]
      _ -> errors
    end
  end
end
