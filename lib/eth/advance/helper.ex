defmodule OcapRpc.Internal.EthTransaction.Helper do
  @moduledoc """
  Contains helper methods to construct and sign Ethereum transactions.
  """

  alias ExthCrypto.Hash.Keccak
  alias ExthCrypto.Signature
  alias OcapRpc.Internal.Utils

  @chain_ids %{
    ethereum_mainnet: 1,
    morden: 2,
    expanse_mainnet: 2,
    ropsten: 3,
    rinkeby: 4,
    ubiq_mainnet: 8,
    ubiq_testnet: 9,
    rootstock_mainnet: 30,
    rootstock_testnet: 31,
    kovan: 42,
    ethereum_classic_mainnet: 61,
    ethereum_classic_testnet: 62,
    ewasm_testnet: 66,
    geth_private_chains: 1337,
    görli: 6284,
    stureby: 314_158
  }

  @doc """
  Generates the signature of the `transaction_digest` by using the `private_key`. The transaction digest
  is the kecacak256 hash of the RLP encoded list of nine elements:
  [nonce, gasprice, gaslimit, to, value, data, v, r, s]

  Returns `{signature, r, s, v}`
  """
  @spec get_signature(binary(), String.t()) :: {binary(), integer(), integer(), integer()}
  def get_signature(transaction_digest, private_key) do
    Signature.sign_digest(
      transaction_digest,
      Utils.hex_to_binary(private_key)
    )
  end

  @doc """
  Gets the digest of the transaction to sign.
  """
  @spec get_transaction_to_sign(
          integer(),
          integer(),
          integer(),
          String.t(),
          integer(),
          String.t()
        ) :: binary()
  def get_transaction_to_sign(nonce, gas_price, gas_limit, to, value, input) do
    # EIP155 spec:
    # when computing the hash of a transaction for purposes of signing or recovering,
    # instead of hashing only the first six elements (ie. nonce, gasprice, startgas, to, value, data),
    # hash nine elements, with v replaced by CHAIN_ID, r = 0 and s = 0
    new_transaction(
      nonce,
      gas_price,
      gas_limit,
      to,
      value,
      input,
      @chain_ids[:ethereum_mainnet],
      0,
      0
    )
    |> ExRLP.encode()
    |> Keccak.kec()
  end

  @doc """
  Gets the raw transaction which is ready to broadcast to the network.
  """
  @spec get_raw_transaction(
          integer(),
          integer(),
          integer(),
          String.t(),
          integer(),
          String.t(),
          integer(),
          integer(),
          integer()
        ) :: String.t()
  def get_raw_transaction(nonce, gas_price, gas_limit, to, value, input, v, r, s) do
    recovery_id = get_recovery_id(v)

    new_transaction(nonce, gas_price, gas_limit, to, value, input, recovery_id, r, s)
    |> ExRLP.encode()
    |> Base.encode16(case: :lower)
  end

  @doc """
  Construct a transaction object in the Ethereum format, which is a list of nince elements' binary values:
  1. `nonce`: The sender's nonce at the current block. Evaluated as empty binary array (<<>>) if it is zero.
  2. `gas_price`:
  3. `gas_limit`:
  4. `to`: Receiver's address. Evaluated as empty binary array (<<>>) if it is null.
  5. `value`: The amount of Wei to transact. Evaluated as empty binary array (<<>>) if it is null or zero.
  6. `input`: The input data. Evaluated as empty binary array (<<>>) if it is null.
  7. `v`: Recover Id. Use chain_id to get a transaction data to sign; use either 37 or 38 (EIP-155) to get the raw transaction to broadcast.
  8. `r`: r value of the ECDS signature. Evaluated as empty binary array (<<>>) if it is null or zero.
  9. `v`: v value of the ECDS signature. Evaluated as empty binary array (<<>>) if it is null or zero.
  """
  @spec new_transaction(
          integer(),
          integer(),
          integer(),
          String.t(),
          integer(),
          String.t(),
          integer(),
          integer(),
          integer()
        ) :: list(binary())
  def new_transaction(nonce, gas_price, gas_limit, to, value, input, v, r, s) do
    to = to || ""
    value = value || nil
    input = input || ""

    [
      to_bytes(nonce),
      to_bytes(gas_price),
      to_bytes(gas_limit),
      Utils.hex_to_binary(to),
      to_bytes(value),
      Utils.hex_to_binary(input),
      to_bytes(v),
      to_bytes(r),
      to_bytes(s)
    ]
  end

  @doc """
  Generates the transaction hash. In Ethereum the data to be hash is the raw transaction.
  """
  @spec get_transaction_hash(String.t()) :: String.t()
  def get_transaction_hash(raw_transaction) do
    raw_transaction
    |> Utils.hex_to_binary()
    |> Keccak.kec()
    |> Base.encode16()
  end

  @doc """
  Gets the corresponding Ethereum address from the `private_key`.
  """
  @spec get_address_from_private_key(String.t()) :: String.t()
  def get_address_from_private_key(private_key) do
    {:ok, <<0x04, public_key::binary>>} =
      private_key |> Utils.hex_to_binary() |> Signature.get_public_key()

    <<_::binary-size(12), address::binary-size(20)>> = Keccak.kec(public_key)

    "0x" <> Base.encode16(address, case: :lower)
  end

  defp get_recovery_id(v) when v in [0, 1], do: @chain_ids[:ethereum_mainnet] * 2 + 35 + v

  defp to_bytes(0), do: ""
  defp to_bytes(""), do: ""
  defp to_bytes(nil), do: ""

  defp to_bytes(number) when is_integer(number) do
    hex = Integer.to_string(number, 16)

    case rem(String.length(hex), 2) do
      0 -> Base.decode16!(hex)
      1 -> Base.decode16!("0" <> hex)
    end
  end
end
