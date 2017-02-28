defmodule Ueberauthfreeagent.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :ueberauth_freeagent,
     version: @version,
     name: "Ueberauth FreeAgent",
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/bruce/ueberauth_freeagent",
     homepage_url: "https://github.com/bruce/ueberauth_freeagent",
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
     {:oauth2, "~> 0.8"},
     {:ueberauth, "~> 0.4"},

     # dev/test only dependencies
     {:credo, "~> 0.5", only: [:dev, :test]},

     # docs dependencies
     {:earmark, "~> 0.2", only: :dev},
     {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"], main: "extra-readme"]
  end

  defp description do
    "An Ueberauth strategy for using FreeAgent to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Bruce Williams"],
      licenses: ["MIT"],
      links: %{"freeagent": "https://github.com/bruce/ueberauth_freeagent"}]
  end
end
