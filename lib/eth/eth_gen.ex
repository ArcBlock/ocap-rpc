defmodule OcapRpc.Internal.EthCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias OcapRpc.Internal.{Erc20, EthAccount, EthRpc, Extractor, Parser}

  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  @erc20_contract "eth_erc20_"
  @account "eth_account_"
  @get_tx "eth_getTransactionBy"
  @get_block "eth_getBlockBy"

  def gen_method(name, method, args, result, opts) do
    cond do
      String.starts_with?(method, @erc20_contract) ->
        method = normalize_method(method, @erc20_contract)
        quote_advance_call(name, args, Erc20, method, result, opts)

      String.starts_with?(method, @account) ->
        method = normalize_method(method, @account)
        quote_advance_call(name, args, EthAccount, method, result, opts)

      String.starts_with?(method, @get_tx) ->
        quote_rpc_call(name, args, method, result, [{:action, :transaction} | opts])

      String.starts_with?(method, @get_block) ->
        quote_rpc_call(name, args, method, result, [{:action, :block} | opts])

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
        |> EthRpc.call(values)
        |> EthRpc.resp_hook(unquote(action))
        |> Extractor.process(unquote(Macro.escape(result)), unquote(mod_type))
      end
    end
  end

  defp quote_advance_call(name, args, mod, method, result, opts) do
    doc = Access.get(opts, :doc)
    mod_type = get_type(opts)

    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        response = apply(unquote(mod), unquote(method), values)
        Extractor.process(response, unquote(Macro.escape(result)), unquote(mod_type))
      end
    end
  end

  defp normalize_method(method, prefix) do
    method |> String.replace_leading(prefix, "") |> String.to_atom()
  end

  defp get_type(opts) do
    type = Access.get(opts, :type)

    case type do
      nil ->
        nil

      _ ->
        mod_name = DynamicModule.gen_module_name(:ocap_rpc, "Eth", "Type", Recase.to_pascal(type))

        String.to_atom("Elixir.#{mod_name}")
    end
  end
end
