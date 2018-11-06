defmodule OcapRpc.Internal.EthABI do
  @moduledoc """
  Decode the input based on the ABI.
  """
  require Logger

  alias OcapRpc.Eth.SignatureDatabase
  alias OcapRpc.Internal.Utils

  @sig_reg ~r{(.*)\((.*)\)}
  @type valid_sig :: {:ok, String.t(), list}
  @type invalid_sig :: {:error, String.t(), Error}

  def parse_input(%{to: to}) when is_nil(to), do: nil
  def parse_input(%{type: "create"}), do: nil

  def parse_input(%{input: input, hash: _hash}) do
    input
    |> slice_input()
    |> decode_input()
    |> return()
  end

  def parse_input(%{
        action: %{input: input},
        transaction_hash: _hash,
        trace_address: _trace_address
      }) do
    input
    |> slice_input()
    |> decode_input()
    |> return()
  end

  def parse_input(_), do: nil

  defp slice_input(input) do
    bin = Utils.hex_to_binary(input)

    if byte_size(bin) < 4 do
      {nil, nil}
    else
      <<sig_bytes::binary-4, input_data::binary>> = bin

      if byte_size(input_data) > 3000 do
        {nil, nil}
      else
        signature =
          sig_bytes
          |> Base.encode16(case: :lower)
          |> SignatureDatabase.get_signatures()

        {signature, input_data}
      end
    end
  end

  def decode_input({nil, _input_data}), do: nil
  def decode_input({[], _input_data}), do: nil

  def decode_input({signatures, ""}) when is_list(signatures) do
    signature = Enum.find(signatures, nil, fn sig -> String.ends_with?(sig, "()") end)

    case signature do
      nil -> nil
      _ -> {:ok, signature, []}
    end
  end

  def decode_input({signature, ""}), do: {:ok, signature, []}

  @doc """
  Decode the transaction input based on the given `signatures`.
  """
  @spec decode_input({list[String.t()], binary}) :: list[invalid_sig()] | valid_sig()
  def decode_input({signatures, input_data}) when is_list(signatures) do
    all_results = Enum.map(signatures, &decode_input({&1, input_data}))

    case all_results do
      nil ->
        nil

      _ ->
        valid_result = Enum.find(all_results, nil, fn item -> elem(item, 0) == :ok end)

        case valid_result do
          nil -> all_results
          _ -> valid_result
        end
    end
  end

  @doc """
  Decode transaction input data. Returns the signature and the arguments list.
  """
  @spec decode_input({String.t(), binary}) :: valid_sig() | invalid_sig()
  def decode_input({signature, input_data}) do
    [_, fn_name, param_types] = Regex.run(@sig_reg, signature)

    # This is a workaround of this issue https://github.com/exthereum/abi/issues/13
    new_signature = fn_name <> "((" <> param_types <> "))"

    try do
      [arg_values] = ABI.decode(new_signature, input_data)
      types = String.split(param_types, ",")
      args = parse_args(types, arg_values)
      {:ok, signature, args}
    rescue
      e -> {:error, signature, e}
    end
  end

  def parse_args(types, args) do
    # assert(length(types) == length(args))

    args
    |> Tuple.to_list()
    |> Enum.zip(types)
    |> Enum.map(&parse_arg/1)
  end

  def parse_arg({arg, "string"}) do
    case String.printable?(arg) do
      true -> arg
      false -> "0x" <> Base.encode16(arg, case: :lower)
    end
  end

  def parse_arg({arg, type})
      when type in [
             "address",
             "byte",
             "bytes",
             "bytes1",
             "bytes2",
             "bytes3",
             "bytes4",
             "bytes5",
             "bytes6",
             "bytes7",
             "bytes8",
             "bytes9",
             "bytes10",
             "bytes11",
             "bytes12",
             "bytes13",
             "bytes14",
             "bytes15",
             "bytes16",
             "bytes17",
             "bytes18",
             "bytes19",
             "bytes20",
             "bytes21",
             "bytes22",
             "bytes23",
             "bytes24",
             "bytes25",
             "bytes26",
             "bytes27",
             "bytes28",
             "bytes29",
             "bytes30",
             "bytes31",
             "bytes32"
           ],
      do: "0x" <> Base.encode16(arg, case: :lower)

  def parse_arg({arg, type}) do
    case String.ends_with?(type, "]") do
      true ->
        inner_type = String.slice(type, 0, index_of_last_bracket(type))
        Enum.map(arg, fn inner_arg -> parse_arg({inner_arg, inner_type}) end)

      false ->
        arg
    end
  end

  # Get index of last '['
  defp index_of_last_bracket(str) do
    {_char, index} =
      str
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.find(fn {char, _index} -> char == ?[ end)

    index
  end

  defp return(decoded_input) do
    case decoded_input do
      nil ->
        nil

      {:ok, signature, args} ->
        {signature, args}

      {:error, _signature, _e} ->
        nil

      list when is_list(list) ->
        nil
    end
  end
end
