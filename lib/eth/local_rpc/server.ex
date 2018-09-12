defmodule OcapRpc.Eth.LocalRpc do
  @moduledoc """
  Load blockchain data from the file. The caller should be responsible to call :load for every batch (100 data).
  State: %{start: from_block, end: to_block, data: %{}}
  """

  use GenServer
  require Logger

  alias OcapRpc.Converter

  def start_link(path) do
    GenServer.start_link(__MODULE__, [path], name: __MODULE__)
  end

  def load(start_num) do
    Logger.info("Load data for #{start_num}")
    GenServer.call(__MODULE__, {:load, start_num})
  end

  def get(method, args) do
    GenServer.call(__MODULE__, {String.to_atom(method), List.flatten(args)})
  end

  # callbacks
  def init(path) do
    block_map = get_block_map(path)

    {:ok,
     %{
       start: 0,
       end: 0,
       block_map: block_map,
       blocks: %{},
       transactions: %{},
       traces: %{},
       receipts: %{}
     }}
  end

  def handle_call({:load, num}, _from, %{block_map: block_map} = state) do
    new_state =
      case num < state[:end] do
        true -> state
        _ -> load_file(block_map, num)
      end

    {:reply, :ok, new_state}
  end

  def handle_call({:eth_getBlockByNumber, [num, _]}, _from, state) do
    result =
      case Map.get(state[:blocks], num) do
        nil -> raise RuntimeError
        data -> Map.put(data, "transactions", Map.get(state[:transactions], num, []))
      end

    {:reply, result, state}
  end

  def handle_call({:trace_block, [num]}, _from, state) do
    result =
      case Map.get(state[:traces], num) do
        nil -> raise RuntimeError
        data -> data
      end

    {:reply, result, state}
  end

  def handle_call({:eth_getTransactionReceipt, hashes}, _from, state) do
    result = Enum.map(hashes, fn hash -> Map.get(state[:receipts], hash) end)

    {:reply, result, state}
  end

  # private functions
  defp load_file(block_map, num) do
    case Map.get(block_map, num) do
      nil ->
        Logger.error("Cannot load #{num} from #{inspect(block_map)}")
        raise RuntimeError

      p ->
        load_files(block_map, num, p)
    end
  end

  defp load_files(block_map, num, p) do
    {blocks, end_num} = load_blocks(p)
    raw_txs = load_raw_txs(p)

    %{
      start: num,
      end: end_num,
      block_map: block_map,
      blocks: blocks,
      transactions: group_txs_by_block(raw_txs),
      traces: load_traces(p),
      receipts: load_receipts(p)
    }
  end

  defp load_blocks(p) do
    p
    |> Path.join("blocks.json")
    |> File.stream!()
    |> Stream.map(&Jason.decode!/1)
    |> Enum.reduce({%{}, 0}, fn data, {acc, _last_num} ->
      num = data["number"] |> Converter.to_int()
      {Map.put(acc, data["number"], data), num}
    end)
  end

  defp load_raw_txs(p) do
    p
    |> Path.join("transactions.json")
    |> File.stream!()
    |> Stream.map(&Jason.decode!/1)
    |> Enum.into([])
  end

  # defp group_txs_by_hash(raw_txs) do
  #   Enum.reduce(raw_txs, %{}, fn item, acc -> Map.put(acc, item["hash"], item) end)
  # end

  defp group_txs_by_block(raw_txs) do
    Enum.group_by(raw_txs, fn item -> item["blockNumber"] end)
  end

  defp load_traces(p) do
    p
    |> Path.join("traces.json")
    |> File.stream!()
    |> Stream.map(&Jason.decode!/1)
    # here we limit the traces to internal transactions and the block reward trace. Rest traces would be dropped
    # |> Stream.filter(fn trace ->
    #   tx = Map.get(txs_by_hash, trace["transactionHash"])
    #   action = trace["action"]

    #   Map.has_key?(action, "rewardType") ||
    #     (tx["to"] == action["from"] and Converter.to_int(action["value"]) > 0 and
    #        action["callType"] == "call")
    # end)
    |> Enum.group_by(fn item -> "0x" <> (item["blockNumber"] |> Converter.to_hex()) end)
  end

  defp load_receipts(p) do
    p
    |> Path.join("receipts.json")
    |> File.stream!()
    |> Stream.map(&Jason.decode!/1)
    |> Enum.reduce(%{}, fn data, acc ->
      Map.put(acc, data["transactionHash"], data)
    end)
  end

  defp get_block_map(path) do
    "/data/rpc/#{path}/*/*"
    |> Path.wildcard()
    |> Enum.reduce(%{}, fn p, acc ->
      num = p |> Path.basename() |> String.to_integer()
      Map.put(acc, num, p)
    end)
  end
end
