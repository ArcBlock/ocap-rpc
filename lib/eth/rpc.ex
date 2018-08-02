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
          [_ | _] = data -> process_batch_result(data)
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
      :block -> get_block_tx_receipt_batch(resp)
      _ -> resp
    end
  end

  # private functions

  defp get_tx_receipt(resp) do
    receipt = request("eth_getTransactionReceipt", [resp["hash"]])
    Map.merge(receipt, resp)
  end

  defp get_block_tx_receipt_batch(resp) do
    tx_list = resp["transactions"]
    first_tx = List.first(tx_list)

    transactions =
      case is_map(first_tx) do
        true ->
          hashes = Enum.map(tx_list, fn tx -> [tx["hash"]] end)

          receipts = request("eth_getTransactionReceipt", [hashes])

          for {tx, receipt} <- Enum.zip(tx_list, receipts) do
            Map.merge(receipt, tx)
          end

        _ ->
          tx_list
      end

    Map.put(resp, "transactions", transactions)
  end

  defp process_batch_result(data) do
    Enum.map(data, fn %{"result" => result} -> result end)
  end

  defp get_body(method, args) do
    case is_list(List.first(args)) do
      true -> encode_many(method, args)
      _ -> encode_single(method, args)
    end
  end

  defp encode_single(method, args) do
    %{
      method: method,
      params: args,
      id: 1,
      jsonrpc: "2.0"
    }
  end

  defp encode_many(method, args) do
    args
    |> List.first()
    |> Enum.with_index(1)
    |> Enum.map(fn {item, idx} ->
      %{
        method: method,
        params: item,
        id: idx,
        jsonrpc: "2.0"
      }
    end)
  end

  defp handle_error(code, msg) do
    Logger.error("Parity RPC error: #{code}: #{msg}")

    {:error, %{code: code, error: msg}}
  end
end
