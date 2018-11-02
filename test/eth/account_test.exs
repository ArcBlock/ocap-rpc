defmodule OcapRpcTest.EthAccount do
  use ExUnit.Case
  import Tesla.Mock

  alias OcapRpc.Eth.Account

  alias OcapRpcTest.MockHttp
  alias OcapRpcTest.TestUtils

  setup do
    mock(fn %{method: :post, body: body} ->
      json(MockHttp.post(body))
    end)

    :ok
  end

  test "account balance should return ether" do
    assert Account.balance(TestUtils.user_account(), :latest) == TestUtils.user_balance()
  end

  test "account code should be empty for user" do
    assert Account.get_code(TestUtils.user_account()) == ""
  end
end
