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

    filename
    |> read_one_file()
    |> Enum.map(fn item ->
      rpc = read_files(dir, item["rpc"])
      type = read_files(dir, item["type"])

      item
      |> Map.put("rpc", rpc)
      |> Map.put("type", type)
      |> Map.take(["name", "doc", "rpc", "type"])
    end)
    |> List.flatten()
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
    IO.inspect(filename)

    case YamlElixir.read_from_file(filename) do
      {:ok, data} ->
        data

      {:error, err} ->
        Logger.error("Error when parsing file: #{filename}")
        raise err
    end
  end
end
