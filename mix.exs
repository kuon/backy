defmodule Backy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :backy,
      version: "1.0.1",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Backy, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:postgrex, "~> 0.17"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A simple background job queue backed by postgresql.
    """
  end

  defp package do
    [
      name: :backy,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Nicolas Goy"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kuon/backy"}
    ]
  end
end
