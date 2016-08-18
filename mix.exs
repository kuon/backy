defmodule Backy.Mixfile do
  use Mix.Project

  def project do
    [app: :backy,
     version: "0.0.10",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :postgrex, :poison],
     mod: {Backy, []}]
  end

  defp deps do
    [{:postgrex, "~> 0.11"},
     {:poison, "~> 2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:markdown, github: "devinus/markdown", only: :dev},
     {:mix_test_watch, "~> 0.2", only: :dev}]
  end

  defp description do
  """
  A simple background job queue backed by postgresql.
  """
  end

  defp package do
    [name: :backy,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Nicolas Goy"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/kuon/backy"}]
  end
end
