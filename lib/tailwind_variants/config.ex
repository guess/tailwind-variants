defmodule TailwindVariants.Config do
  @moduledoc """
  Configuration module for TailwindVariants.
  """

  @default_config %{
    tw_merge: true
  }

  @doc """
  Returns the merged configuration.
  """
  def config(custom_config \\ %{}) do
    Map.merge(@default_config, custom_config)
  end
end
