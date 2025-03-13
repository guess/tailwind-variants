defmodule TailwindVariants.Component do
  @moduledoc """
  Represents a tailwind-variants component.
  """

  @enforce_keys [:config]
  defstruct [
    :base,
    :slots,
    :variants,
    :default_variants,
    :compound_variants,
    :compound_slots,
    :config
  ]
end
