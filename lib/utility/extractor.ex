defmodule OcapRpc.Internal.Extractor do
  @moduledoc """
  Extract information based on DSL definition
  """
  require Logger
  alias OcapRpc.Converter

  @doc """
  Process the response data with predefined mapping
  """
  def process(data, mapping) do
    data
    |> process_data(mapping)
    |> AtomicMap.convert(safe: false)
  end

  defp process_data(data, nil), do: data

  defp process_data(data, mapping) when is_map(data) do
    mapping
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      try do
        Map.put(acc, k, transform(v, data, Recase.to_camel(k)))
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
    result = process_data(%{"result" => data}, %{"result" => mapping})
    Map.get(result, :result)
  end

  defp process_data(data, _), do: data

  defp transform("_", data, key), do: Map.get(data, key)
  defp transform("*", data, _key), do: AtomicMap.convert(data, safe: false)
  defp transform("&" <> fn_info, data, key), do: call_function(fn_info, data, key)

  # process normal case like "gas_limit" or complicate case "action.gas"
  defp transform(v, data, _key) when is_binary(v) do
    path =
      v
      |> String.split(".")
      |> Enum.map(&Recase.to_camel(&1))

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
        camel_key =
          case String.contains?(key, "_") do
            true -> Recase.to_camel(key)
            _ -> key
          end

        case transform(name, data, camel_key) do
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
