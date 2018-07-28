defmodule OcapRpc.Internal.EthCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias OcapRpc.Internal.{Erc20, EthAccount, EthRpc, Extractor, Parser}

  @erc20_contract "eth_erc20_"
  @account "eth_account_"
  @get_tx "eth_getTransactionBy"

  def gen_method(name, method, args, result, doc) do
    cond do
      String.starts_with?(method, @erc20_contract) ->
        method = normalize_method(method, @erc20_contract)
        quote_advance_call(name, args, Erc20, method, result, doc)

      String.starts_with?(method, @account) ->
        method = normalize_method(method, @account)
        quote_advance_call(name, args, EthAccount, method, result, doc)

      String.starts_with?(method, @get_tx) ->
        quote_tx_call(name, args, method, result, doc)

      true ->
        quote_rpc_call(name, args, method, result, doc)
    end
  end

  defp quote_rpc_call(name, args, method, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        unquote(method)
        |> EthRpc.request(values)
        |> Extractor.process(unquote(Macro.escape(result)))
      end
    end
  end

  # TODO(tchen): this fun shall be merged with quote_rpc_call in future.
  defp quote_tx_call(name, args, method, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        values = Enum.map(unquote(args), fn k -> Keyword.get(binding(), k) end)

        resp_hook = fn resp ->
          receipt = EthRpc.request("eth_getTransactionReceipt", [resp["hash"]])
          Map.merge(receipt, resp)
        end

        unquote(method)
        |> EthRpc.request(values)
        |> resp_hook.()
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
