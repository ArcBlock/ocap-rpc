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
      {:atomic_map, "> 0.0.0"},
      {:decimal, "~> 1.1"},
      {:hexate, ">= 0.6.0"},
      {:httpoison, "~> 0.13"},
      {:jason, "~> 1.1"},
      {:keccakf1600, "~> 2.0", hex: :keccakf1600_orig, override: true},
      {:proper_case, "~> 1.2.0"},
      {:recase, "~> 0.3.0"},
      {:yaml_elixir, "~> 2.0.0"},

      # utility tools for error logs and metrics
      {:logger_sentry, "~> 0.1.5"},
      {:recon, "~> 2.3.2"},
      {:recon_ex, "~> 0.9.1"},
      {:sentry, "~> 6.4.0"},

      # utility belt
      # {:utility_belt, path: "/Users/tchen/projects/mycode/utility_belt"},
      {:utility_belt, "> 0.0.0"},

      # deployment
      {:distillery, "~> 1.5", runtime: false},

      # dev & test
      {:benchee, "~> 0.13.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.18.0", only: [:dev, :test], runtime: false},
      {:excheck, "~> 0.5", only: :test, runtime: false},
      {:pre_commit_hook, "~> 1.2", only: [:dev, :test], runtime: false},
      {:triq, github: "triqng/triq", only: :test, runtime: false},

      # test only
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:faker, "~> 0.10", only: [:dev, :test]},
      {:mock, "~> 0.3.1", only: [:dev, :test]}
    ]
  end
end
