defmodule OcapRpc.Internal.EthTransaction do
  @moduledoc """
  Parse transaction for further information
  """
  require Logger

  alias OcapRpc.Eth.SignatureDatabase

  @sig_reg ~r{(.*)\((.*)\)}

  def parse_input(transaction) when is_map(transaction) do
    cond do
      transaction.to == nil -> nil
      byte_size(transaction.input) < 8 -> nil
      true -> transaction.input |> Base.decode16!(case: :lower) |> parse_input()
    end
  end

  def parse_input(binary_input) when is_binary(binary_input) do
    <<sig_bytes::binary-4, input_data::binary>> = binary_input

    sig_bytes
    |> Base.encode16(case: :lower)
    |> SignatureDatabase.get_signatures()
    |> decode_transaction_input(input_data)
  end

  def decode_transaction_input(nil, _input_data), do: nil
  def decode_transaction_input([], _input_data), do: nil

  @doc """
  Decode the transaction input based on the given `signatures`.
  """
  @spec decode_transaction_input(list[String.t()], binary) :: nil | {String.t(), list}
  def decode_transaction_input(signatures, input_data) when is_list(signatures) do
    signatures
    |> Enum.map(&decode_transaction_input(&1, input_data))
    |> Enum.find(nil, fn item -> item != nil end)
  end

  @doc """
  Decode transaction input data.
  """
  @spec decode_transaction_input(String.t(), binary) :: nil | {String.t(), list}
  def decode_transaction_input(signature, input_data) do
    [_, fn_name, params] = Regex.run(@sig_reg, signature)

    # This is a workaround of this issue https://github.com/exthereum/abi/issues/13
    new_signature = fn_name <> "((" <> params <> "))"

    try do
      [tuple] = ABI.decode(new_signature, input_data)
      types = String.split(params, ",")
      args = parse_args(types, tuple)
      {signature, args}
    rescue
      RuntimeError -> nil
    end
  end

  def parse_args(types, args) do
    # assert(length(types) == length(args))

    args
    |> Tuple.to_list()
    |> Enum.zip(types)
    |> Enum.map(&parse_arg/1)
  end

  def parse_arg({arg, "address"}), do: "0x" <> Base.encode16(arg, case: :lower)
  def parse_arg({arg, _type}), do: arg
end
