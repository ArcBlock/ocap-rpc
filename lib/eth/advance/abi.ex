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

  def parse_input(%{input: input, hash: hash}) do
    input
    |> slice_input()
    |> decode_input()
    |> log_and_return(hash, [-1], input)
  end

  def parse_input(%{
        action: %{input: input},
        transaction_hash: hash,
        trace_address: trace_address
      }) do
    input
    |> slice_input()
    |> decode_input()
    |> log_and_return(hash, trace_address, input)
  end

  def parse_input(_), do: nil

  defp slice_input(input) do
    case Utils.hex_to_binary(input) do
      bin when byte_size(bin) < 8 ->
        {nil, nil}

      bin ->
        <<sig_bytes::binary-4, input_data::binary>> = bin

        signature =
          sig_bytes
          |> Base.encode16(case: :lower)
          |> SignatureDatabase.get_signatures()

        {signature, input_data}
    end
  end

  def decode_input({nil, _input_data}), do: nil
  def decode_input({[], _input_data}), do: nil
  def decode_input({signature, ""}), do: {:ok, signature, []}

  @doc """
  Decode the transaction input based on the given `signatures`.
  """
  @spec decode_input({list[String.t()], binary}) :: list[invalid_sig()] | valid_sig()
  def decode_input({signatures, input_data}) when is_list(signatures) do
    all_results = Enum.map(signatures, &decode_input({&1, input_data}))
    valid_result = Enum.find(all_results, nil, fn item -> elem(item, 0) == :ok end)

    case valid_result do
      nil -> all_results
      _ -> valid_result
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

  def parse_arg({arg, "string"}), do: arg

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

  defp log_and_return(decoded_input, hash, trace_address, input) do
    case decoded_input do
      nil ->
        nil

      {:ok, signature, args} ->
        {signature, args}

      {:error, signature, e} ->
        log(hash, trace_address, input, signature, e)

      list ->
        Enum.each(list, fn {:error, signature, e} ->
          log(hash, trace_address, input, signature, e)
        end)

        nil
    end
  end

  defp log(hash, trace_address, input, signature, e) do
    Logger.warn(
      "Unable to decode the input. Transaction Hash: #{hash}, Trace Address: #{
        inspect(trace_address)
      }, Input: #{input}, Signature: #{signature}, Error: #{Exception.message(e)}, Error trace; #{
        Exception.format(:error, e)
      }"
    )

    nil
  end
end
