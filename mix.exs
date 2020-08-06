defmodule Etsy.MixProject do
  use Mix.Project

  @version "0.1.0-alpha"

  def project do
    [
      app: :etsy,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description:
        "Etsy API Client",

      # Docs
      name: "Etsy",
      source_url: "https://github.com/spencerdcarlson/etsy",
      docs: docs()
    ]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "overview",
      extra_section: "GUIDES",
      formatters: ["html", "epub"],
      extras: ["guides/overview.md"],
      groups_for_extras: [Guides: ~r/guides\/[^\/]+\.md/]
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      files: ~w(CHANGELOG* config LICENSE* README* lib mix.exs .formatter.exs),
      links: %{
        "GitHub" => "https://github.com/spencerdcarlson/etsy"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Etsy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.15"},
      {:jason, "~> 1.0"},
      {:oauther, "~> 1.1"},
      {:credo, "~> 1.4"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
