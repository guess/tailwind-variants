defmodule TailwindVariants.TestAssertions do
  @moduledoc """
  Test helpers for TailwindVariants testing.
  """

  @doc """
  Compares two strings of Tailwind classes to see if they match, regardless of order.

  This helper splits each string into individual classes, sorts them, and then compares
  the resulting lists. This avoids test failures due to class ordering differences.

  ## Examples

      iex> assert_classes_match("p-4 text-red-500", "text-red-500 p-4")
      true

      iex> assert_classes_match("p-4 text-red-500", "p-4 text-blue-500")
      ** (ExUnit.AssertionError)
         Expected classes to match.

         Expected: ["p-4", "text-red-500"]
         Got: ["p-4", "text-blue-500"]

         Difference:
         * Different: "text-red-500" != "text-blue-500"
  """
  def assert_classes_match(expected, actual) do
    expected_classes = normalize_classes(expected)
    actual_classes = normalize_classes(actual)

    if expected_classes == actual_classes do
      true
    else
      # Find differences for better error reporting
      only_in_expected = expected_classes -- actual_classes
      only_in_actual = actual_classes -- expected_classes

      message = """
      Expected classes to match.

      Expected: #{inspect(expected_classes)}
      Got: #{inspect(actual_classes)}

      #{difference_message(only_in_expected, only_in_actual)}
      """

      ExUnit.Assertions.flunk(message)
    end
  end

  @doc """
  Normalize a string of classes by splitting, trimming, and sorting.
  Empty or nil values are filtered out.
  """
  def normalize_classes(nil), do: []
  def normalize_classes(""), do: []

  def normalize_classes(classes) when is_binary(classes) do
    classes
    |> String.split(~r/\s+/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.sort()
  end

  # Helper for better error messages
  defp difference_message([], []), do: "Classes are the same but in different order."

  defp difference_message(only_in_expected, only_in_actual) do
    [
      if(only_in_expected != [], do: "Only in expected: #{inspect(only_in_expected)}", else: nil),
      if(only_in_actual != [], do: "Only in actual: #{inspect(only_in_actual)}", else: nil)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
