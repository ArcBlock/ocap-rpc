use Mix.Config

# log related
config :logger,
  level: :debug,
  utc_log: false

config :logger, :console,
  format: "$date $time [$level] $levelpad$message\n",
  colors: [info: :green]

config :ocap_rpc, :eth,
  conn: %{
    hostname: "localhost",
    port: 8545
  }

config :ocap_rpc, :btc,
  conn: %{
    hostname: "localhost",
    port: 8332
  }

config :ocap_rpc,
  env: Mix.env()

import_config "#{Mix.env()}.exs"
