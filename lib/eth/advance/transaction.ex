defmodule OcapRpc.Internal.EthTransaction do
  @moduledoc """
  Parse transaction for further information
  """
  require Logger

  alias OcapRpc.Converter
  alias OcapRpc.Internal.Utils

  @method_sigs [
                 "approve(address,uint256)",
                 "transferFrom(address,address,uint256)",
                 "unpause()",
                 "decreaseApproval(address,uint256)",
                 "pause()",
                 "transfer(address,uint256)",
                 "increaseApproval(address,uint256)",
                 "transferOwnership(address)"
               ]
               |> Enum.reduce(%{}, fn name, acc ->
                 sig = "0x" <> Utils.get_method_sig(name)
                 fn_name = name |> String.split("(") |> List.first()
                 arity = name |> String.split(",") |> length()
                 Map.put(acc, sig, {fn_name, arity, name})
               end)

  def parse_input(%{input: "0x"}), do: nil
  def parse_input(%{input: "0x00"}), do: nil

  def parse_input(data) when is_map(data) do
    <<sig::binary-10, rest::binary>> = data.input

    {method, _arity, fn_sig} =
      case Map.get(@method_sigs, sig) do
        nil -> {"unknownMethod", 0, "n/a"}
        v -> v
      end

    args = get_args(rest)
    input_plain = get_input_plain(fn_sig, sig, args)

    case method do
      "transfer" ->
        [to, value | _] = args

        update_tx(data, data.from, to, value, input_plain)

      "transferFrom" ->
        [from, to, value] = args
        update_tx(data, from, to, value, input_plain)

      _ ->
        data
    end
  rescue
    e ->
      Logger.error(
        "Cannot process input data. Error: #{Exception.message(e)}. Tx hash is #{data.hash}. Input: #{
          data.input
        }."
      )

      update_tx(data, nil, nil, nil, "")
  end

  defp update_tx(data, from, to, value, input) do
    data
    |> Map.put(:contract_from, from)
    |> Map.put(:contract_to, to)
    |> Map.put(:contract_value, Converter.to_ether(value))
    |> Map.put(:input_plain, input)
  end

  defp get_input_plain(fn_sig, sig, args) do
    args
    |> Enum.with_index()
    |> Enum.reduce("Function: #{fn_sig}\nMethodID: #{sig}", fn {item, idx}, acc ->
      acc <> "\n[#{idx}]: #{item}"
    end)
  end

  defp get_args(data),
    do: for(<<arg::binary-64 <- data>>, do: "0x" <> (arg |> String.trim_leading("0")))
end
