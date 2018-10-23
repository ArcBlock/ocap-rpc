defmodule OcapRpc.Internal.Extractor do
  @moduledoc """
  Extract information based on DSL definition
  """
  require Logger
  alias OcapRpc.Converter

  @doc """
  Process the response data with predefined mapping
  """
  def process(data, mapping, type) when is_list(data) do
    Enum.map(data, fn item -> process(item, mapping, type) end)
  end

  def process(data, mapping, type) do
    result =
      data
      |> AtomicMap.convert(safe: false)
      |> process_data(mapping)

    cond do
      not is_map(result) -> result
      Map.has_key?(result, :__struct__) -> result
      not is_nil(type) -> struct(type, result)
      true -> result
    end
  end

  defp process_data(data, nil), do: data

  defp process_data(data, mapping) when is_map(data) do
    result =
      mapping
      |> Enum.reduce(data, fn {k, action}, acc ->
        result = transform(action, acc, k)

        case is_map(result) and Map.has_key?(result, k) do
          true -> result
          _ -> Map.put(acc, k, result)
        end
      end)

    case mapping_to_type(mapping) do
      nil -> result
      type -> struct(type, result)
    end
  end

  defp process_data(data, mapping) when is_list(data) do
    data
    |> Enum.map(&process_data(&1, mapping))
    |> Enum.reject(&is_nil/1)
  end

  defp process_data(data, mapping) when is_binary(mapping) do
    # this is to make sure we go back and do AtomicMap
    result = process(%{result: data}, %{result: mapping}, nil)
    Map.get(result, :result)
  end

  defp process_data(data, _), do: data

  defp transform("_", data, key), do: Map.get(data, key)
  defp transform("*", data, _key), do: data
  defp transform("&" <> fn_info, data, key), do: call_function(fn_info, data, key)

  # process normal case like "gas_limit" or complicate case "action.gas"
  defp transform(action, data, _key) when is_binary(action) do
    path =
      action
      |> String.split(".")
      |> Enum.map(&String.to_atom(&1))

    get_in(data, path)
  end

  defp transform(v, data, key) do
    # IO.inspect(binding())

    value = Map.get(data, key)

    case is_nil(value) do
      true ->
        nil

      false ->
        value
        |> Enum.map(&process_data(&1, v))
        |> Enum.reject(&is_nil/1)
    end
  end

  defp call_function(fn_info, data, key) do
    [fn_name | args] =
      ~r/[a-zA-Z_*\.]+/
      |> Regex.scan(fn_info)
      |> List.flatten()

    arg_list =
      args
      |> Enum.map(fn name ->
        case transform(name, data, key) do
          # we'd like to strip the 0x, so that further processing is easy
          "0x" <> v ->
            v

          ret ->
            ret
        end
      end)

    apply(Converter, String.to_atom(fn_name), arg_list)
  end

  defp mapping_to_type([{k, _} | _] = _mapping) do
    case k do
      :block_hash -> OcapRpc.Eth.Type.Transaction
      :miner -> OcapRpc.Eth.Type.Block
      :reward_type -> OcapRpc.Eth.Type.BlockReward
      :trace_address -> OcapRpc.Eth.Type.TransactionTrace
      :log_index -> OcapRpc.Eth.Type.TransactionLog
      :reward -> OcapRpc.Eth.Type.Uncle
      _ -> nil
    end
  end

  defp mapping_to_type(_), do: nil
end
