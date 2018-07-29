defmodule OcapRpcTest.EthAccount do
  use ExUnit.Case
  import Mock
  import OcapRpcTest.MockHttp

  alias OcapRpc.Eth.Account

  alias OcapRpcTest.TestUtils

  test "account balance should return ether" do
    with_mock(HTTPoison, post: &post/4) do
      assert Account.balance(TestUtils.user_account()) == TestUtils.user_balance()
    end
  end

  test "account code should be empty for user" do
    with_mock(HTTPoison, post: &post/4) do
      assert Account.get_code(TestUtils.user_account()) == ""
    end
  end
end
