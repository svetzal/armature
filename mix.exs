defmodule Armature.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/svetzal/armature"

  def project do
    [
      app: :armature,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "The structure under a Phoenix design system: levels, composition rules, " <>
          "a token contract and accessible baseline components.",
      package: package(),
      name: "Armature",
      source_url: @source_url,
      docs: docs(),
      test_coverage: [
        summary: [threshold: 80],
        ignore_modules: [~r/^Example\./, First, Inner, Primitive]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},

      # Development and testing
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Stacey Vetzal"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(lib priv guides usage-rules.md .formatter.exs mix.exs README.md CHANGELOG.md LICENSE.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/tokens.md",
        "guides/components.md",
        "guides/catalogue.md",
        "CHARTER.md",
        "CHANGELOG.md",
        "LICENSE.md"
      ]
    ]
  end
end
