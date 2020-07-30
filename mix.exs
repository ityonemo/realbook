defmodule Realbook.MixProject do
  use Mix.Project

  def project do
    [
      app: :realbook,
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env:
        [coveralls: :test,
         "coveralls.detail": :test,
         "coveralls.post": :test,
         "coveralls.html": :test,
         release: :lab],
      package: [
          description: "Elixir Server deployment and provisioning tool",
          licenses: ["MIT"],
          files: ~w(lib mix.exs README* LICENSE* VERSIONS* guides),
          links: %{"GitHub" => "https://github.com/ityonemo/realbook"}
        ],
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/_support"]
  def elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: {Realbook.Storage, []}
    ]
  end

  def docs do
    guides = __DIR__
    |> Path.join("guides")
    |> File.ls!
    |> Enum.filter(&(Path.extname(&1) == ".md"))
    |> Enum.sort
    |> Enum.map(&"guides/#{&1}")

    [
      main: "Realbook",
      source_url: "https://github.com/ityonemo/realbook",
      extra_section: "guides",
      extras: guides
    ]
  end

  defp deps do
    [
      {:librarian, "~> 0.1.12"},
      {:nimble_parsec, "~> 0.6"},

      # test and support dependencies
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.11", only: :test, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false}
    ]
  end
end
