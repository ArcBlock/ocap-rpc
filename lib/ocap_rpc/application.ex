defmodule OcapRpc.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: OcapRpc.Supervisor]

    update_config()

    Supervisor.start_link(children, opts)
  end

  defp update_config do
    app = :ocap_rpc
    update_conn(app, :btc)
    update_conn(app, :eth)
  end

  defp update_conn(app, :btc = type) do
    conf = Application.get_env(app, type)

    conn =
      conf
      |> Access.get(:conn)
      |> Map.put(:hostname, System.get_env("BTC_RPC_HOST") || "localhost")
      |> Map.put(:user, System.get_env("BTC_RPC_USER"))
      |> Map.put(:password, System.get_env("BTC_RPC_PASS"))

    Application.put_env(app, type, Keyword.put(conf, :conn, conn))
  end

  defp update_conn(app, :eth = type) do
    conf = Application.get_env(app, type)

    conn =
      conf
      |> Access.get(:conn)
      |> Map.put(:hostname, System.get_env("ETH_RPC_HOST") || "localhost")

    Application.put_env(app, type, Keyword.put(conf, :conn, conn))
  end
end
