defmodule BlockchainRpc.Internal.Abt do
  @moduledoc """
  Contract method for ABT.
  """
  alias BlockchainRpc.Eth.Chain
  alias BlockchainRpc.Internal.Utils

  @contract_addr "0xB98d4C97425d9908E66E53A6fDf673ACcA0BE986"
  def balance_of(from) do
    obj = %{
      from: from,
      to: @contract_addr,
      data: Utils.sig_balance_of(from)
    }

    Chain.call(obj)
  end
end
