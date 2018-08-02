defmodule OcapRpc.Internal.Parser do
  @moduledoc """
  Private utility for generator
  """
  require Logger

  @doc """
  get the directory of priv/rpc
  """
  def get_dir(type), do: Application.app_dir(:ocap_rpc, "priv/rpc/#{type}")

  def read_main(type) do
    dir = get_dir(type)
    filename = Path.join(dir, "main.yml")

    data = read_one_file(filename)
    rpc = read_files(dir, data["rpc"])
    result = read_files(dir, data["result"])

    data
    |> Map.put("rpc", rpc)
    |> Map.put("result", merge_types(result))
    |> Map.take(["name", "doc", "rpc", "result"])
  end

  def gen_args(args) do
    Enum.map(args, fn name -> Macro.var(name, nil) end)
  end

  # private functions

  defp read_files(dir, filenames) do
    filenames
    |> Enum.map(&read_one_file(dir, &1))
    |> List.flatten()
    |> Enum.reject(fn item -> is_nil(item) || (is_map(item) && map_size(item) == 0) end)
  end

  defp read_one_file(dir, name), do: read_one_file(Path.join(dir, name))

  defp read_one_file(filename) do
    case YamlElixir.read_from_file(filename) do
      {:ok, data} ->
        data

      {:error, err} ->
        Logger.error("Error when parsing file: #{filename}")
        raise err
    end
  end

  defp merge_types(types) do
    types = List.flatten(types)

    Enum.reduce(types, %{}, fn item, acc ->
      {k, v} = get_kv(item)
      Map.put(acc, k, update_type(acc, v))
    end)
  end

  defp update_type(types, item) do
    item
    |> Enum.map(fn item ->
      {k, v} = get_kv(item)

      result =
        case is_binary(v) and String.starts_with?(v, "@") do
          true ->
            Map.get(types, String.trim_leading(v, "@"))

          _ ->
            v
        end

      {String.to_atom(k), result}
    end)
  end

  defp get_kv(map), do: {get_one(map, :keys), get_one(map, :values)}
  defp get_one(map, type), do: List.first(apply(Map, type, [map]))
end
