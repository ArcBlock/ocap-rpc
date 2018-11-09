# Block Chain RPC

Provide basic RPC functionalities for various Chain, in elixir way.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ocap_rpc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ocap_rpc, "~> 0.0.0"}
  ]
end
```

## Configuration

```elixir
config :ocap_rpc, :eth,
  conn: %{
    hostname: "localhost",
    port: 8545
  },
  timeout: 5_000

config :ocap_rpc, :btc,
  conn: %{
    hostname: "localhost",
    port: 8332
  },
  timeout: 5_000

config :ocap_rpc, :ipfs,
  conn: %{
    hostname: "localhost",
    port: 5001
  },
  timeout: 5_000

config :ocap_rpc, :cmt,
  conn: %{
    hostname: "localhost",
    port: 8545
  },
  timeout: 5_000
```

## Environment Variable Dependencies

To let ocap_rpc work correctly, please make sure you have following environment variables set in runtime environment.

  - BTC_RPC_HOST
  - BTC_RPC_USER
  - BTC_RPC_PASS
  - ETH_RPC_HOST
  - CMT_RPC_HOST

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_bitcoin](https://hexdocs.pm/ex_bitcoin).
