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
    types = Enum.reduce(types, %{}, fn item, acc -> Map.merge(acc, item) end)
    Enum.reduce(types, %{}, fn {k, v}, acc -> Map.put(acc, k, update_type(types, v)) end)
  end

  defp update_type(types, item) do
    item
    |> Enum.into(%{}, fn {k, v} ->
      result =
        case is_binary(v) and String.starts_with?(v, "@") do
          true ->
            Map.get(types, String.trim_leading(v, "@"))

          _ ->
            v
        end

      {k, result}
    end)
  end
end
