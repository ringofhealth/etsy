defmodule Etsy.MixProject do
  use Mix.Project

  def project do
    [
      app: :etsy,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:jason, "~> 1.2"},
      {:oauther, "~> 1.1"},
      {:credo, "~> 1.4"}
    ]
  end
end
