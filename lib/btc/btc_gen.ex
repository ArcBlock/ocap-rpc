defmodule OcapRpc.Internal.BtcCodeGen do
  @moduledoc """
  Bitcoin specific code generator
  """
  alias OcapRpc.Internal.{BtcRpc, Extractor, Parser}
  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  @mem_pool_transaction [
    "getrawmempool",
    "getmempoolancestors",
    "getmempooldescendants",
    "getmempoolentry"
  ]
  @get_raw_transaction "getrawtransaction"
  @list_address_groupings "listaddressgroupings"
  @get_blockchain_info "getblockchaininfo"

  def gen_method(name, method, args, result, opts) do
    cond do
      Enum.member?(@mem_pool_transaction, method) ->
        quote_rpc_call(name, args, method, result, [{:action, :mem_pool_transaction} | opts])

      String.starts_with?(method, @get_raw_transaction) ->
        quote_rpc_call(name, args, method, result, [{:action, :get_raw_transaction} | opts])

      String.starts_with?(method, @list_address_groupings) ->
        quote_rpc_call(name, args, method, result, [{:action, :list_address_groupings} | opts])

      String.starts_with?(method, @get_blockchain_info) ->
        quote_rpc_call(name, args, method, result, [{:action, :get_blockchain_info} | opts])

      true ->
        quote_rpc_call(name, args, method, result, opts)
    end
  end

  defp quote_rpc_call(name, args, method, result, opts) do
    action = Access.get(opts, :action)
    doc = Access.get(opts, :doc)
    mod_type = get_type(opts)

    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        unquote(method)
        |> BtcRpc.call(values)
        |> BtcRpc.resp_hook(unquote(action))
        |> Extractor.process(unquote(Macro.escape(result)), unquote(mod_type))
      end
    end
  end

  defp get_type(opts) do
    type = Access.get(opts, :type)

    case type do
      nil ->
        nil

      _ ->
        mod_name = DynamicModule.gen_module_name(:ocap_rpc, "Btc", "Type", Recase.to_pascal(type))

        String.to_atom("Elixir.#{mod_name}")
    end
  end
end
