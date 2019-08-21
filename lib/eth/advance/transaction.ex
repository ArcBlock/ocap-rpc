defmodule OcapRpc.Internal.EthTransaction do
  @moduledoc """
  Contains methods to construct and sign Ethereum transactions.
  """
  alias OcapRpc.Eth.Account
  alias OcapRpc.Eth.Chain
  alias OcapRpc.Eth.Transaction
  alias OcapRpc.Internal.EthTransaction.Helper

  @doc """
  Signs and then broadcasts the transaction, returns the transaction hash.
  """
  def send_transaction(nonce, gas_price, gas_limit, to, value, input, private_key) do
    nonce = get_next_nonce(private_key, nonce)
    gas_price = get_gas_price(gas_price)

    nonce
    |> get_raw_transaction(gas_price, gas_limit, to, value, input, private_key)
    |> Transaction.send_raw()
  end

  defp get_raw_transaction(nonce, gas_price, gas_limit, to, value, input, private_key) do
    {_signature, r, s, v} =
      nonce
      |> Helper.get_transaction_to_sign(gas_price, gas_limit, to, value, input)
      |> Helper.get_signature(private_key)

    "0x" <> Helper.get_raw_transaction(nonce, gas_price, gas_limit, to, value, input, v, r, s)
  end

  defp get_next_nonce(private_key, nil) do
    private_key
    |> Helper.get_address_from_private_key()
    |> Account.get_next_nonce()
  end

  defp get_next_nonce(_, nonce), do: nonce

  defp get_gas_price(nil), do: Chain.gas_price()
  defp get_gas_price(gas_price), do: gas_price
end
