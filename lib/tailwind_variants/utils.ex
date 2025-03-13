defmodule TailwindVariants.Utils do
  @moduledoc """
  Utility functions for manipulating class names.
  """

  @doc """
  Joins class names, handling nil, empty strings, and nested arrays.

  ## Examples

      iex> join_class_names(["font-bold", "text-lg"])
      "font-bold text-lg"

      iex> join_class_names(["font-bold", nil, "text-lg"])
      "font-bold text-lg"

      iex> join_class_names(["font-bold", ["text-lg", "p-4"]])
      "font-bold text-lg p-4"
  """
  def join_class_names(classes) do
    TwMerge.join(classes)
  end

  @doc """
  Merges class names using tw_merge if enabled in config.

  ## Examples

      iex> merge_class_names(["p-4", "p-6"], %{tw_merge: true})
      "p-6"

      iex> merge_class_names(["p-4", "p-6"], %{tw_merge: false})
      "p-4 p-6"
  """
  def merge_class_names(classes, config) do
    if Map.get(config, :tw_merge, true) && Code.ensure_loaded?(TwMerge) do
      TwMerge.merge(classes)
    else
      join_class_names(classes)
    end
  end

  @doc """
  Recursively converts all keys in a map to strings.
  Handles nested maps and lists of maps.

  ## Examples
      iex> stringify_keys(%{name: "John", age: 30})
      %{"name" => "John", "age" => 30}

      iex> stringify_keys(%{user: %{name: "John", age: 30}})
      %{"user" => %{"name" => "John", "age" => 30}}
  """
  def stringify_keys(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn {k, v} -> {convert_to_string(k), stringify_keys(v)} end)
  end

  def stringify_keys(value) when is_list(value) do
    Enum.map(value, &stringify_keys/1)
  end

  def stringify_keys(value), do: value

  # Handle both atoms and strings
  defp convert_to_string(key) when is_atom(key), do: Atom.to_string(key)
  defp convert_to_string(key) when is_binary(key), do: key
  defp convert_to_string(key), do: to_string(key)

  @doc """
  Convert a map to atom keys.
  Warning that this is not a recursive function and is unsafe and could
  result in a denial of service attack if you exceed the atom limit.

  ## Examples
      iex> atomize_keys(%{"name" => "John", "age" => 30})
      %{name: "John", age: 30}

      iex> atomize_keys(%{"user" => %{"name" => "John", "age" => 30}})
      %{user: %{name: "John", age: 30}}
  """
  def atomize_keys(map) when is_map(map) and not is_struct(map) do
    Map.new(map, fn {k, v} -> {try_existing_atom(k), atomize_keys(v)} end)
  end

  def atomize_keys(value) when is_list(value) do
    Enum.map(value, &atomize_keys/1)
  end

  def atomize_keys(value), do: value

  @doc """
  Convert a string to an atom.
  """
  def try_existing_atom(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end

  def try_existing_atom(key), do: key
end
