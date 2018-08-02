defmodule OcapRpc.Internal.Extractor do
  @moduledoc """
  Extract information based on DSL definition
  """
  require Logger
  alias OcapRpc.Converter

  @doc """
  Process the response data with predefined mapping
  """
  def process(data, mapping, type) when is_list(data),
    do: Enum.map(data, fn item -> process(item, mapping, type) end)

  def process(data, mapping, type) do
    mapping = AtomicMap.convert(mapping, safe: false)

    result =
      data
      |> AtomicMap.convert(safe: false)
      |> process_data(mapping)

    case type do
      nil -> result
      _ -> struct(type, result)
    end
  end

  defp process_data(data, nil), do: data

  defp process_data(data, mapping) when is_map(data) do
    mapping
    |> Enum.reduce(data, fn {k, v}, acc ->
      try do
        result = transform(v, acc, k)

        case is_map(result) and Map.has_key?(result, k) do
          true -> result
          _ -> Map.put(acc, k, result)
        end
      rescue
        e ->
          Logger.error("Error: #{Exception.message(e)}, trace; #{Exception.format(:error, e)}")

          acc
      end
    end)
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
  defp transform(v, data, _key) when is_binary(v) do
    path =
      v
      |> String.split(".")
      |> Enum.map(&String.to_atom(&1))

    get_in(data, path)
  end

  defp transform(v, data, key) when is_map(v) do
    data
    |> Map.get(key)
    |> Enum.map(&process_data(&1, v))
    |> Enum.reject(&is_nil/1)
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
end
