defmodule OcapRpc.Internal.EthRpc do
  @moduledoc """
  RPC request to ethereum parity server
  """
  use Tesla
  require Logger

  alias OcapRpc.Converter

  # plug(Tesla.Middleware.Retry, delay: 500, max_retries: 3)

  @headers [{"content-type", "application/json"}]
  @timeout :ocap_rpc |> Application.get_env(:eth) |> Keyword.get(:timeout)

  plug(Tesla.Middleware.Headers, @headers)

  # TODO(lei): when tesla not compatible issue solved: `https://github.com/teamon/tesla/issues/157`
  if Application.get_env(:ocap_rpc, :env) not in [:test] do
    plug(Tesla.Middleware.Timeout, timeout: Application.get_env(:ocap_rpc, :timeout, 240_000))
  end

  def call(method, args) do
    %{hostname: hostname, port: port} =
      :ocap_rpc |> Application.get_env(:eth) |> Keyword.get(:conn)

    body = get_body(method, args)
    # Logger.debug("Ethereum RPC request for: #{inspect(body)}}")
    result =
      post(
        "http://#{hostname}:#{to_string(port)}",
        Jason.encode!(body)
      )

    case result do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"id" => _, "result" => result} -> result
          [_ | _] = data -> process_batch_result(data)
          %{"error" => %{"code" => code, "message" => msg}} -> handle_error(code, msg)
        end

      {:error, reason} ->
        raise(
          "RPC call failed. Reason: #{inspect(reason)}, method: #{inspect(method)}, arguments: #{
            inspect(args)
          }"
        )

      # TODO: unfortunately eth json rpc returns everything as 200, break out here as a TODO
      _ ->
        raise RuntimeError
    end
  end

  def resp_hook(resp, type \\ nil) do
    case type do
      :transaction -> get_tx_trace(resp)
      :block -> get_block_trace(resp)
      _ -> resp
    end
  end

  # private functions
  defp get_tx_trace(nil), do: nil

  defp get_tx_trace(resp) do
    hash = resp["hash"]

    case call("eth_getTransactionReceipt", [resp["hash"]]) do
      nil ->
        nil

      receipt ->
        block = call("eth_getBlockByHash", [resp["blockHash"], false])

        traces =
          "trace_transaction"
          |> call([hash])
          |> Kernel.||([])
          |> Enum.map(fn trace -> Map.put(trace, "status", receipt["status"]) end)

        receipt
        |> Map.merge(resp)
        |> Map.put("traces", traces)
        |> Map.put("timestamp", block["timestamp"])
    end
  end

  defp get_block_trace(nil), do: nil

  defp get_block_trace(resp) do
    tx_list = resp["transactions"]
    blocktime = resp["timestamp"] |> Converter.to_int() |> Kernel.*(1000)
    first_tx = List.first(tx_list)

    traces =
      "trace_block"
      |> call([resp["number"]])
      |> Enum.group_by(fn tx -> tx["transactionHash"] end)

    rewards =
      traces
      |> Map.get(nil)
      |> Enum.map(fn trace -> Map.put(trace, "timestamp", blocktime) end)

    uncle_details = prepare_uncles(rewards, resp["number"], resp["uncles"])

    transactions =
      case is_map(first_tx) do
        true ->
          hashes = Enum.map(tx_list, fn tx -> [tx["hash"]] end)
          receipts = call("eth_getTransactionReceipt", [hashes])

          tx_list =
            for {tx, receipt} <- Enum.zip(tx_list, receipts) do
              (receipt || %{})
              |> Map.merge(tx)
            end

          tx_list
          |> Enum.map(fn tx ->
            tx = Map.put(tx, "timestamp", blocktime + Converter.to_int(tx["transactionIndex"]))
            Map.put(tx, "traces", update_traces(Map.get(traces, tx["hash"]), tx))
          end)

        _ ->
          tx_list
      end

    resp
    |> Map.put("transactions", transactions)
    |> Map.put("rewards", rewards)
    |> Map.put("uncles", uncle_details)
  end

  defp update_traces(traces, tx) do
    traces
    |> Enum.map(fn trace ->
      trace
      |> Map.put("timestamp", tx["timestamp"])
      |> Map.put("status", tx["status"])
    end)
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

  defp prepare_uncles(_, _, []), do: []

  defp prepare_uncles(rewards, block_number, uncles) do
    uncle_rewards =
      Enum.filter(rewards, fn reward -> reward["action"]["rewardType"] == "uncle" end)

    uncles
    |> get_uncles_details(block_number)
    |> Enum.zip(uncle_rewards)
    |> Enum.map(fn {detail, reward} ->
      Map.put(detail, "reward", reward["action"]["value"])
    end)
  end

  defp get_uncles_details(uncles, number) do
    uncles
    |> Enum.with_index()
    |> Enum.map(fn {_hash, index} ->
      call("eth_getUncleByBlockNumberAndIndex", [number, "0x" <> Hexate.encode(index)])
    end)
  end

  defp encode_single(method, args) do
    %{
      method: method,
      params: encode_params(args),
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
        params: encode_params(item),
        id: idx,
        jsonrpc: "2.0"
      }
    end)
  end

  defp encode_params(args) when is_list(args), do: Enum.map(args, &encode_params/1)

  defp encode_params(args) when is_map(args),
    do: Enum.reduce(args, %{}, fn {k, v}, acc -> Map.put(acc, k, encode_params(v)) end)

  defp encode_params(arg) when is_integer(arg), do: Converter.to_hex(arg)
  defp encode_params("0x" <> _ = arg), do: arg
  defp encode_params(arg) when is_binary(arg), do: "0x" <> arg
  defp encode_params(arg), do: arg

  defp handle_error(code, msg) do
    Logger.error("Parity RPC error: #{code}: #{msg}")

    {:error, %{code: code, error: msg}}
  end
end
