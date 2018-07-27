defmodule BlockchainRpc.Internal.Erc20 do
  @moduledoc """
  Contract method for ABT.
  """
  alias BlockchainRpc.Eth.Chain
  alias BlockchainRpc.Internal.Utils

  @contract_addrs %{
    abt: "0xB98d4C97425d9908E66E53A6fDf673ACcA0BE986",
    ae: "0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d",
    aion: "0x4CEdA7906a5Ed2179785Cd3A40A69ee8bc99C466",
    ctxc: "0xea11755ae41d889ceec39a63e6ff75a02bc1c00d"
  }

  def balance_of(token, from) do
    obj = %{
      from: from,
      to: Map.get(@contract_addrs, token),
      data: Utils.sig_balance_of(from)
    }

    Chain.call(obj)
  end

  def total_supply(token) do
    obj = %{
      to: Map.get(@contract_addrs, token),
      data: Utils.sig_total_supply()
    }

    Chain.call(obj)
  end
end
