defmodule BlockchainRpc.Internal.Utils do
  @moduledoc """
  Utility functions
  """

  def sha3(data) do
    data |> :keccakf1600.sha3_256() |> Base.encode16() |> String.downcase()
  end

  def call_data(method, value) do
    value = value |> String.replace_leading("0x", "") |> String.pad_leading(64, ["0"])
    method_sig = method |> sha3() |> String.slice(0, 8)
    "0x#{method_sig}#{value}"
  end

  def sig_balance_of(from) do
    call_data("balanceOf(address)", from)
  end

  def sig_total_supply do
    call_data("totalSupply()", "")
  end
end
