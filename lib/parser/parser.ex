defmodule OcapRpc.Internal.Parser do
  @moduledoc """
  Private utility for generator
  """

  @doc """
  get the directory of priv/rpc
  """
  def get_dir(type), do: Application.app_dir(:ocap_rpc, "priv/rpc/#{type}")

  @doc """
  Retrieve data from ``priv/rpc`` and return as a list
  """
  def get_data(type) do
    dir = get_dir(type)

    "#{dir}/*.yml"
    |> Path.wildcard()
    |> Enum.map(&read/1)
  end

  def gen_args(args) do
    Enum.map(args, fn name -> Macro.var(name, nil) end)
  end

  # private functions
  defp read(file) do
    {:ok, data} = YamlElixir.read_from_file(file)
    data
  end
end
