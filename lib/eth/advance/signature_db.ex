defmodule OcapRpc.Eth.SignatureDatabase do
  @moduledoc """
  Provides mapping of all recoginized signature bytes and signatures.
  """

  @signatures :ocap_rpc
              |> Application.app_dir()
              |> Path.join('priv/sig_db/sig_data.json')
              |> File.read!()
              |> Jason.decode!()
              |> Enum.reduce(
                %{},
                fn item, acc ->
                  "0x" <> sig_bytes = item["sig_bytes"]
                  Map.put(acc, String.downcase(sig_bytes), item["signatures"])
                end
              )

  def signatures, do: @signatures

  def get_signatures(sig_bytes), do: Map.get(@signatures, sig_bytes, nil)
end
