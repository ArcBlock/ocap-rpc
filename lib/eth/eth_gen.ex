defmodule OcapRpc.Internal.EthCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias OcapRpc.Internal.{Erc20, EthRpc, Extractor, Parser}

  @erc20_contract "eth_erc20_"

  def gen_method(name, method, args, result, doc) do
    case String.starts_with?(method, @erc20_contract) do
      true -> quote_eth_contract_call(name, args, method, result, doc)
      _ -> quote_rpc_call(name, args, method, result, doc)
    end
  end

  defp quote_rpc_call(name, args, method, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        args = Enum.map(binding(), fn {_, v} -> v end)

        response = EthRpc.request(unquote(method), args)
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end

  defp quote_eth_contract_call(name, args, method, result, doc) do
    method = method |> String.replace_leading(@erc20_contract, "") |> String.to_atom()

    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        args = Enum.map(binding(), fn {_, v} -> v end)

        response = apply(Erc20, unquote(method), args)
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end
end
