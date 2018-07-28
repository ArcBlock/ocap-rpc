defmodule OcapRpc.Internal.EthCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias OcapRpc.Internal.{Erc20, EthAccount, EthRpc, Extractor, Parser}

  @erc20_contract "eth_erc20_"
  @account "eth_account_"
  @get_tx "eth_getTransactionBy"
  @get_block "eth_getBlockBy"

  def gen_method(name, method, args, result, doc) do
    cond do
      String.starts_with?(method, @erc20_contract) ->
        method = normalize_method(method, @erc20_contract)
        quote_advance_call(name, args, Erc20, method, result, doc)

      String.starts_with?(method, @account) ->
        method = normalize_method(method, @account)
        quote_advance_call(name, args, EthAccount, method, result, doc)

      String.starts_with?(method, @get_tx) ->
        quote_rpc_call(name, args, method, result, doc, :transaction)

      String.starts_with?(method, @get_block) ->
        quote_rpc_call(name, args, method, result, doc, :block)

      true ->
        quote_rpc_call(name, args, method, result, doc)
    end
  end

  defp quote_rpc_call(name, args, method, result, doc, type \\ nil) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        unquote(method)
        |> EthRpc.request(values)
        |> EthRpc.resp_hook(unquote(type))
        |> Extractor.process(unquote(Macro.escape(result)))
      end
    end
  end

  defp quote_advance_call(name, args, mod, method, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        response = apply(unquote(mod), unquote(method), values)
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end

  defp normalize_method(method, prefix) do
    method |> String.replace_leading(prefix, "") |> String.to_atom()
  end
end
