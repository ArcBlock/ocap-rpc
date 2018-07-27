use Mix.Config

# log related
config :logger,
  level: :info,
  utc_log: false

config :logger, :console,
  format: "$date $time [$level] $levelpad$message\n",
  colors: [info: :green]

config :blockchain_rpc, :eth,
  conn: %{
    hostname: "localhost",
    port: 8545
  },
  chunk_size: 1000

config :blockchain_rpc, :btc,
  conn: %{
    hostname: "localhost",
    port: 8332
  },
  chunk_size: 1000

import_config "#{Mix.env()}.exs"
