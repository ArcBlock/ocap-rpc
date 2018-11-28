defmodule OcapRpc.MixProject do
  use Mix.Project

  @version File.cwd!() |> Path.join("version") |> File.read!() |> String.trim()
  @elixir_version File.cwd!() |> Path.join(".elixir_version") |> File.read!() |> String.trim()
  @otp_version File.cwd!() |> Path.join(".otp_version") |> File.read!() |> String.trim()

  def get_version, do: @version
  def get_elixir_version, do: @elixir_version
  def get_otp_version, do: @otp_version

  def project do
    [
      app: :ocap_rpc,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OcapRpc.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # convert
      {:atomic_map, "~> 0.9"},
      {:decimal, "~> 1.6"},
      {:hexate, ">= 0.6.0"},
      {:proper_case, "~> 1.3"},
      {:recase, "~> 0.3"},
      {:yaml_elixir, "~> 2.1"},

      # http client
      {:tesla, "~> 1.2"},
      {:jason, "~> 1.1"},

      # Ethereum related deps
      {:abi, git: "https://github.com/arcblock/abi.git", tag: "master"},
      # {:abi, path: "/Users/peiling/Documents/GitHub/ArcBlock/abi"},

      # logger and sentry
      {:logger_sentry, "~> 0.2"},
      {:sentry, "~> 7.0"},

      # recon
      {:recon, "~> 2.3"},
      {:recon_ex, "~> 0.9.1"},

      # utility belt
      {:utility_belt, github: "arcblock/utility_belt", tag: "v0.12.0"},

      # deployment
      {:distillery, "~> 2.0", runtime: false},

      # dev & test
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:excheck, "~> 0.6", only: :test, runtime: false},
      {:pre_commit_hook, "~> 1.2", only: [:dev, :test], runtime: false},
      {:triq, "~> 1.3", only: :test, runtime: false},

      # test only
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:faker, "~> 0.11", only: [:dev, :test]},
      {:mock, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
