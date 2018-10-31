defmodule OcapRpc.Internal.IpfsRpc do
  @moduledoc """
  RPC request to ipfs server
  """
  use Tesla
  require Logger

  @version "v0"

  # TODO(lei): when tesla not compatible issue solved: `https://github.com/teamon/tesla/issues/157`
  if Application.get_env(:ocap_rpc, :env) not in [:test] do
    plug(Tesla.Middleware.Timeout, timeout: Application.get_env(:ocap_rpc, :timeout, 240_000))
  end

  def call(method, verb, args) do
    %{hostname: hostname, port: port} =
      :ocap_rpc |> Application.get_env(:ipfs) |> Keyword.get(:conn)

    url = "http://#{hostname}:#{to_string(port)}/api/#{@version}/#{method}"

    Logger.debug(fn ->
      "IPFS RPC request to #{verb} for: #{inspect(url)}. args: #{inspect(args)}"
    end)

    result = apply(Tesla, verb, [url, [query: args]])

    case result do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type = get_header(headers, "content-type")

        case content_type do
          "application/json" -> Jason.decode!(body)
          _ -> body
        end

      {:ok, %{status: status, body: body}} ->
        Logger.error("Status: #{status}. Result: #{inspect(body)}")
        raise RuntimeError

      {:error, reason} ->
        raise(
          "RPC call failed. Reason: #{inspect(reason)}, method: #{inspect(method)}, arguments: #{
            inspect(args)
          }"
        )

      e ->
        Logger.error(e)
        raise RuntimeError
    end
  end

  defp get_header(headers, name) do
    Enum.reduce_while(headers, nil, fn {k, v}, _acc ->
      if k === name, do: {:halt, v}, else: {:cont, nil}
    end)
  end
end
