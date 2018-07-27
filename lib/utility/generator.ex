defmodule BlockchainRpc.Internal.EthCode do
  @moduledoc """
  Generate RPC code based on priv/rpc/*.yml.
  """
  alias BlockchainRpc.Internal.{BtcRpc, Erc20, EthRpc, Extractor, Parser}
  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  @eth_contract_prefix "eth_contract_"

  def gen(data, type, opts \\ []) do
    api = Map.get(data, "api")
    result = Map.get(data, "result", nil)

    type_name = type |> Atom.to_string() |> Recase.to_pascal()
    mod_name = DynamicModule.gen_module_name(:blockchain_rpc, type_name, Map.get(api, "name"))

    rpc_mod =
      case type do
        :eth -> EthRpc
        :btc -> BtcRpc
        _ -> :not_implemented
      end

    preamble =
      quote do
      end

    contents =
      api
      |> Map.get("public")
      |> Enum.map(fn %{"name" => name, "method" => method, "args" => args} = public ->
        doc = Map.get(public, "desc", "Need public interface doc")
        api_result = Map.get(public, "result", nil)
        result = merge_result(api_result, result)

        case String.starts_with?(method, @eth_contract_prefix) do
          true -> quote_eth_contract_call(name, args, method, result, doc)
          _ -> quote_rpc_call(name, args, method, rpc_mod, result, doc)
        end
      end)

    DynamicModule.gen(
      mod_name,
      preamble,
      contents,
      [{:doc, Map.get(api, "desc", "Need module doc")} | opts]
    )
  end

  defp quote_rpc_call(name, args, method, rpc_mod, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        args = Enum.map(binding(), fn {_, v} -> v end)

        response = apply(unquote(rpc_mod), :request, [unquote(method), args])
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end

  defp quote_eth_contract_call(name, args, method, result, doc) do
    method = method |> String.replace_leading(@eth_contract_prefix, "")
    ["erc20", fn_name] = String.split(method, "_", parts: 2)
    fn_name = String.to_atom(fn_name)

    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        args = Enum.map(binding(), fn {_, v} -> v end)

        response = apply(Erc20, unquote(fn_name), args)
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end

  defp merge_result(api_result, base_result) do
    case base_result != nil and is_binary(api_result) do
      true -> Map.get(base_result, api_result, api_result)
      _ -> api_result
    end
  end
end
