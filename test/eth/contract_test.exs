defmodule OcapRpcTest.EthContract do
  use ExUnit.Case
  import Tesla.Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Contract
  alias OcapRpcTest.TestUtils

  setup do
    mock(fn %{method: :post, body: body} ->
      json(post(body))
    end)

    :ok
  end

  test "Should return current balance of the account for a token" do
    assert Contract.balance(:abt, TestUtils.user_account()) == TestUtils.user_balance()
  end

  test "Should return total supply for a token" do
    assert Contract.total_supply(:abt) == TestUtils.abt_supply() |> Converter.to_supply_amount()
  end

  test "Should return a list of transactions for a token" do
    [tx | _] = Contract.get_transactions(:abt, nil, nil, 10000, 0)
    assert tx.hash == TestUtils.tx_hash()
  end
end
