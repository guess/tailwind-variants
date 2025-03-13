defmodule TailwindVariants do
  @moduledoc """
  Provides a variant system for TailwindCSS in Elixir applications.

  This library allows you to create components with variants, slots, and more,
  similar to the JavaScript tailwind-variants library.
  """
  alias TailwindVariants.Component
  alias TailwindVariants.Utils

  @doc """
  Creates a tailwind-variants component with the given options.

  ## Options

  * `:base` - Base classes for the component
  * `:slots` - Map of slot names to their classes
  * `:variants` - Map of variant names to their values
  * `:default_variants` - Map of variant names to their default values
  * `:compound_variants` - List of compound variants
  * `:compound_slots` - List of compound slots
  * `:extend` - Another component to extend
  * `:config` - Configuration options

  ## Examples

      iex> component = tv(%{base: "font-medium text-white"})
      iex> component.base
      "font-medium text-white"

      iex> component = tv(%{
      ...>   base: "font-medium text-white",
      ...>   variants: %{
      ...>     color: %{
      ...>       primary: "bg-blue-500",
      ...>       secondary: "bg-purple-500"
      ...>     }
      ...>   }
      ...> })
      iex> component.variants.color.primary
      "bg-blue-500"
  """
  def tv(options) do
    # Set default configuration
    config = Map.get(options, :config, %{tw_merge: true})

    # Extract component parts from options
    base = Map.get(options, :base, "")
    slots = Map.get(options, :slots)
    variants = Map.get(options, :variants, %{})
    default_variants = Map.get(options, :default_variants, %{})
    compound_variants = Map.get(options, :compound_variants, [])
    compound_slots = Map.get(options, :compound_slots, [])
    extended = Map.get(options, :extend)

    # Create the component struct
    %Component{
      base: merge_base(extended, base, config),
      slots: merge_slots(extended, slots, config),
      variants: merge_variants(extended, variants),
      default_variants: merge_default_variants(extended, default_variants),
      compound_variants: merge_compound_variants(extended, compound_variants),
      compound_slots: merge_compound_slots(extended, compound_slots),
      config: config
    }
  end

  @doc """
  Returns a map of all available variants and their possible values for a component.
  Useful for generating documentation or validation.

  ## Example

      iex> button = tv(%{variants: %{color: %{primary: "", secondary: ""}}})
      iex> variant_options(button)
      %{color: [:primary, :secondary]}
  """
  def variant_options(component) do
    component.variants
    |> Enum.map(fn {key, values} -> {key, Map.keys(values)} end)
    |> Map.new()
  end

  @doc """
  See `class_list/2`.
  """
  def tw(component_or_slot, props \\ %{}) do
    class_list(component_or_slot, props)
  end

  # Merge base classes from extended component
  defp merge_base(nil, base, _config), do: base
  defp merge_base(%{base: nil}, base, _config), do: base

  defp merge_base(%{base: extended_base}, base, config) do
    Utils.merge_class_names([extended_base, base], config)
  end

  # Merge slots
  defp merge_slots(nil, slots, _config), do: slots
  defp merge_slots(_extended, nil, _config), do: nil
  defp merge_slots(%{slots: nil}, slots, _config), do: slots

  defp merge_slots(%{slots: extended_slots}, slots, config) do
    merge_fn = fn _k, extended_slot, slot ->
      Utils.merge_class_names([extended_slot, slot], config)
    end

    Map.merge(extended_slots, slots, merge_fn)
  end

  # Merge variants from extended component
  defp merge_variants(nil, variants), do: variants
  defp merge_variants(%{variants: nil}, variants), do: variants

  defp merge_variants(%{variants: extended_variants}, variants) do
    # Define a function to merge variant values
    merge_fn = fn _k, extended_variant, variant ->
      Map.merge(extended_variant, variant)
    end

    Map.merge(extended_variants, variants, merge_fn)
  end

  # Merge default variants from extended component
  defp merge_default_variants(nil, default_variants), do: default_variants
  defp merge_default_variants(%{default_variants: nil}, default_variants), do: default_variants

  defp merge_default_variants(%{default_variants: extended_defaults}, default_variants) do
    Map.merge(extended_defaults, default_variants)
  end

  # Merge compound variants from extended component
  defp merge_compound_variants(nil, compound_variants), do: compound_variants

  defp merge_compound_variants(%{compound_variants: nil}, compound_variants),
    do: compound_variants

  defp merge_compound_variants(%{compound_variants: extended_compounds}, compound_variants) do
    extended_compounds ++ compound_variants
  end

  # Merge compound slots from extended component
  defp merge_compound_slots(nil, compound_slots), do: compound_slots
  defp merge_compound_slots(%{compound_slots: nil}, compound_slots), do: compound_slots

  defp merge_compound_slots(%{compound_slots: extended_compounds}, compound_slots) do
    extended_compounds ++ compound_slots
  end

  @doc """
  Applies props to a component to generate class names.

  ## Parameters

  * `component` - A component created with `tv/1`
  * `props` - A map of props to apply to the component

  ## Returns

  * A string of class names (if no slots are defined)
  * A map of slot functions (if slots are defined)

  ## Examples

      iex> component = tv(%{base: "font-medium text-white"})
      iex> class_list(component)
      "font-medium text-white"

      iex> component = tv(%{
      ...>   base: "font-medium",
      ...>   variants: %{
      ...>     color: %{
      ...>       primary: "bg-blue-500",
      ...>       secondary: "bg-purple-500"
      ...>     }
      ...>   }
      ...> })
      iex> class_list(component, %{color: "primary"})
      "font-medium bg-blue-500"
  """
  def class_list(component_or_slot, props \\ %{})

  def class_list(slot_fn, props) when is_function(slot_fn) do
    slot_fn.(props)
  end

  def class_list(%Component{} = component, props) do
    if component.slots do
      # Handle components with slots
      generate_slot_functions(component, props)
    else
      # Handle simple components
      generate_class_names(component, props)
    end
  end

  # Generate class names for a simple component
  defp generate_class_names(component, props) do
    # Start with base classes
    base_classes = component.base || ""

    # Apply variant classes
    variant_classes = apply_variants(component, props)

    # Apply compound variant classes
    compound_classes = apply_compound_variants(component, props)

    # Apply class overrides
    override_classes = Map.get(props, :class, "")

    # Merge all classes
    Utils.merge_class_names(
      [base_classes, variant_classes, compound_classes, override_classes],
      component.config
    )
  end

  # Apply variants based on props
  defp apply_variants(component, props) do
    # Start with an empty string
    Enum.reduce(Map.keys(component.variants || %{}), "", fn variant_key, acc ->
      # Get the variant value from props or default_variants
      variant_value = get_variant_value(variant_key, props, component.default_variants)

      if variant_value do
        # Get the classes for this variant
        variant_value = try_existing_atom(variant_value)
        variant_classes = get_in(component.variants, [variant_key, variant_value])

        # Merge with accumulated classes
        Utils.merge_class_names([acc, variant_classes], component.config)
      else
        acc
      end
    end)
  end

  # Get variant value from props or default_variants
  defp get_variant_value(variant_key, props, default_variants) do
    # Check props first, then default_variants

    case Map.get(props, variant_key) do
      nil -> Map.get(default_variants || %{}, variant_key)
      value -> value
    end
  end

  # Apply compound variants based on props
  defp apply_compound_variants(component, props) do
    Enum.reduce(component.compound_variants || [], "", fn compound_variant, acc ->
      # Check if all conditions match
      if conditions_match?(compound_variant, props, component.default_variants) do
        # Get the compound variant classes
        compound_classes = Map.get(compound_variant, :class, "")

        # Merge with accumulated classes
        Utils.merge_class_names([acc, compound_classes], component.config)
      else
        acc
      end
    end)
  end

  # Check if all conditions in a variant definition match the props
  defp conditions_match?(conditions, props, default_variants) do
    # Extract only the condition key-value pairs (removing keys like :class, :slots)
    # TODO: Do not need to remove slots
    condition_pairs =
      conditions
      |> Map.drop([:class, :slots])
      |> Enum.to_list()

    # Check if all conditions match
    Enum.all?(condition_pairs, fn {key, value} ->
      prop_value = get_variant_value(key, props, default_variants)

      cond do
        is_list(value) -> prop_value in value
        true -> prop_value == value
      end
    end)
  end

  # Generate slot functions for a component with slots
  defp generate_slot_functions(component, props) do
    # For each slot, create a function that will generate the class names for that slot
    Enum.reduce(Map.keys(component.slots), %{}, fn slot_key, acc ->
      slot_fn = fn slot_props ->
        # Start with the slot's base classes
        base_classes = Map.get(component.slots, slot_key, "")

        # Apply slot-specific variant classes
        variant_classes = apply_slot_variants(component, props, slot_key)

        # Apply slot-specific compound variant classes
        compound_classes = apply_slot_compound_variants(component, props, slot_key)

        # Apply slot-specific compound slot classes
        compound_slot_classes = apply_compound_slots(component, props, slot_key)

        # Apply slot-specific class overrides
        override_classes = Map.get(slot_props, :class, "")

        # Merge all classes
        Utils.merge_class_names(
          [
            base_classes,
            variant_classes,
            compound_classes,
            compound_slot_classes,
            override_classes
          ],
          component.config
        )
      end

      # Add the slot function to the accumulator
      Map.put(acc, slot_key, slot_fn)
    end)
  end

  # Apply slot-specific variant classes
  defp apply_slot_variants(component, props, slot_key) do
    # Start with an empty string
    Enum.reduce(Map.keys(component.variants || %{}), "", fn variant_key, acc ->
      # Get the variant value from props or default_variants
      variant_value = get_variant_value(variant_key, props, component.default_variants)

      if variant_value do
        # Get the variant for this key
        variant_value = try_existing_atom(variant_value)
        variant = get_in(component.variants, [variant_key, variant_value])

        # Get the slot-specific classes for this variant
        slot_classes = if is_map(variant), do: Map.get(variant, slot_key, ""), else: variant

        # Merge with accumulated classes
        Utils.merge_class_names([acc, slot_classes], component.config)
      else
        acc
      end
    end)
  end

  # Apply slot-specific compound variant classes
  defp apply_slot_compound_variants(component, props, slot_key) do
    Enum.reduce(component.compound_variants || [], "", fn compound_variant, acc ->
      # Check if all conditions match

      if conditions_match?(compound_variant, props, component.default_variants) do
        # Get the compound variant classes for this slot
        classes = Map.get(compound_variant, :class, %{})
        slot_classes = if is_map(classes), do: Map.get(classes, slot_key, ""), else: ""

        # Merge with accumulated classes
        Utils.merge_class_names([acc, slot_classes], component.config)
      else
        acc
      end
    end)
  end

  # Apply compound slot classes
  defp apply_compound_slots(component, props, slot_key) do
    Enum.reduce(component.compound_slots || [], "", fn compound_slot, acc ->
      # Get the slots list
      slots = Map.get(compound_slot, :slots, []) |> Enum.map(&try_existing_atom/1)

      # Check if current slot is in the slots list and all conditions match
      if slot_key in slots && conditions_match?(compound_slot, props, component.default_variants) do
        # Get the compound slot classes
        classes = Map.get(compound_slot, :class, "")

        # Merge with accumulated classes
        Utils.merge_class_names([acc, classes], component.config)
      else
        acc
      end
    end)
  end

  # Safely try to convert a string to an existing atom
  defp try_existing_atom(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end

  defp try_existing_atom(key), do: key
end
