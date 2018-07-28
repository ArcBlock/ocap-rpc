defmodule OcapRpc.Internal.EthRpc do
  @moduledoc """
  RPC request to ethereum parity server
  """
  require Logger

  @headers %{
    "Content-Type" => "application/json"
  }

  def request(method, args) do
    config = Application.get_env(:ocap_rpc, :eth)
    %{hostname: hostname, port: port} = Keyword.get(config, :conn)

    body = get_body(method, args)
    # Logger.debug("Ethereum RPC request for: #{inspect(body)}}")

    options = [timeout: 30_000, recv_timeout: 20_000]

    case HTTPoison.post(
           "http://#{hostname}:#{to_string(port)}/",
           Poison.encode!(body),
           @headers,
           options
         ) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"id" => _, "result" => result} -> result
          %{"error" => %{"code" => code, "message" => msg}} -> handle_error(code, msg)
        end

      # TODO: unfortunately eth json rpc returns everything as 200, break out here as a TODO
      _ ->
        raise RuntimeError
    end
  end

  def resp_hook(resp, type \\ nil) do
    case type do
      :transaction -> get_tx_receipt(resp)
      :block -> get_block_tx_receipt(resp)
      _ -> resp
    end
  end

  # private functions

  defp get_tx_receipt(resp) do
    receipt = request("eth_getTransactionReceipt", [resp["hash"]])
    Map.merge(receipt, resp)
  end

  defp get_block_tx_receipt(resp) do
    transactions =
      resp
      |> Map.get("transactions")
      |> Enum.map(fn tx ->
        case is_map(tx) do
          true ->
            receipt = request("eth_getTransactionReceipt", [tx["hash"]])
            Map.merge(receipt, tx)

          _ ->
            tx
        end
      end)

    Map.put(resp, "transactions", transactions)
  end

  defp get_body(method, args) do
    %{
      method: method,
      params: args,
      id: 1,
      jsonrpc: "2.0"
    }
  end

  defp handle_error(code, msg) do
    Logger.error("Parity RPC error: #{code}: #{msg}")

    {:error, %{code: code, error: msg}}
  end
end
