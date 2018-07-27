defmodule BlockchainRpc.Internal.Extractor do
  @moduledoc """
  Extract information based on DSL definition
  """
  require Logger
  alias BlockchainRpc.Internal.DSLUtils

  @doc """
  Process the response data with predefined mapping
  """
  def process(data, nil), do: data

  def process(data, mapping) when is_map(data) do
    mapping
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      try do
        Map.put(acc, k, transform(v, data, Recase.to_camel(k)))
      rescue
        _ ->
          acc
      end
    end)
  end

  def process(data, mapping) when is_list(data) do
    Enum.map(data, &process(&1, mapping))
  end

  def process(data, mapping) do
    result = process(%{"result" => data}, %{"result" => mapping})
    Map.get(result, "result")
  end

  defp transform("_", data, key), do: Map.get(data, key)
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
    |> Enum.map(&process(&1, v))
  end

  defp call_function(fn_info, data, key) do
    [fn_name | args] =
      ~r/[a-zA-Z_\.]+/
      |> Regex.scan(fn_info)
      |> List.flatten()

    arg_list =
      args
      |> Enum.map(fn name ->
        case transform(name, data, Recase.to_camel(key)) do
          # we'd like to strip the 0x, so that further processing is easy
          "0x" <> v ->
            v

          ret ->
            ret
        end
      end)

    apply(DSLUtils, String.to_atom(fn_name), arg_list)
  end
end
