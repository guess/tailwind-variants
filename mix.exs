defmodule TailwindVariants.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description "Tailwind Variants for Elixir - A port of the tailwind-variants library"
  @source_url "https://github.com/guess/tailwind-variants"

  def project do
    [
      app: :tailwind_variants,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {TailwindVariants.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tw_merge, "~> 0.1.1"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md": [title: "Tailwind Variants"]
      ],
      assets: "assets",
      logo: ".github/assets/cover.png"
    ]
  end
end
