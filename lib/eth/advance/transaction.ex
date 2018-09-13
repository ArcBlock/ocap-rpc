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
                 sig = Utils.get_method_sig(name)
                 fn_name = name |> String.split("(") |> List.first()
                 arity = name |> String.split(",") |> length()
                 Map.put(acc, sig, {fn_name, arity, name})
               end)

  def parse_input(%{input: "", tx_type: "contract_execution"} = data) do
    # TODO(tchen): need to make sure this is the right calculation
    trace =
      data.traces
      |> Enum.filter(fn trace ->
        trace.from == data.to and trace.value > 0 and trace.call_type == "call"
      end)
      |> List.first()

    case trace do
      nil -> update_tx(data, nil, nil, nil, "")
      _ -> update_tx(data, data.from, trace.to, trace.value, "")
    end
  end

  def parse_input(%{input: ""} = data), do: update_tx(data, nil, nil, nil, "")
  def parse_input(%{input: "00"} = data), do: update_tx(data, nil, nil, nil, "")

  def parse_input(data) when is_map(data) do
    <<sig::binary-8, rest::binary>> = data.input

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

        if to != nil && byte_size(to) > 40 do
          raise("The length of contract_to is greater than 20 bytes.")
        end

        update_tx(data, data.from, to, value, input_plain)

      "transferFrom" ->
        [from, to, value] = args

        if to != nil && byte_size(to) > 40 do
          raise("The length of contract_to is greater than 20 bytes.")
        end

        update_tx(data, from, to, value, input_plain)

      _ ->
        update_tx(data, nil, nil, nil, "")
    end
  rescue
    e ->
      Logger.warn(
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
    |> Map.put(:contract_value, Converter.to_int(value))
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
    do: for(<<arg::binary-64 <- data>>, do: arg |> String.trim_leading("0"))
end
