defmodule OcapRpcTest.EthContract do
  use ExUnit.Case
  import Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Converter
  alias OcapRpc.Eth.Contract
  alias OcapRpcTest.TestUtils

  test "Should return current balance of the account for a token" do
    with_mock(HTTPoison, post: &post/4) do
      assert Contract.balance(:abt, TestUtils.user_account()) == TestUtils.user_balance()
    end
  end

  test "Should return total supply for a token" do
    with_mock(HTTPoison, post: &post/4) do
      assert Contract.total_supply(:abt) == TestUtils.abt_supply() |> Converter.to_supply_amount()
    end
  end

  test "Should return a list of transactions for a token" do
    with_mock(HTTPoison, post: &post/4) do
      [tx | _] = Contract.get_transactions(:abt, nil, nil, 10000)
      assert tx.hash == TestUtils.tx_hash()
    end
  end
end
