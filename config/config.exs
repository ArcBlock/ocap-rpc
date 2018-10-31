use Mix.Config

# log related
config :logger,
  level: :info,
  utc_log: false

config :logger, :console,
  format: "$date $time [$level] $levelpad$message\n",
  colors: [info: :green]

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

config :ocap_rpc,
  env: Mix.env()

# There are some transactions that have huge input data which leads to memory leak
# when tries to decode its ABI.
config :ocap_rpc, :abi,
  ignored_transactions: [
    "d4144955be257182665c7be541b573341294c0536d56bb7094b17953374def8c",
    "4a425ce69d2aedac5fb708e17836585d4515935df53ffa6005b02c085d8e29c2"
  ]

import_config "#{Mix.env()}.exs"
