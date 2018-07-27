defmodule OcapRpc.Internal.CodeGen do
  @moduledoc """
  Generate RPC code based on priv/rpc/*.yml.
  """
  alias OcapRpc.Internal.{BtcCodeGen, EthCodeGen}
  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  def gen(data, type, opts \\ []) do
    api = Map.get(data, "api")
    result = Map.get(data, "result", nil)

    type_name = type |> Atom.to_string() |> Recase.to_pascal()
    mod_name = DynamicModule.gen_module_name(:ocap_rpc, type_name, Map.get(api, "name"))

    code_gen =
      case type do
        :eth -> EthCodeGen
        :btc -> BtcCodeGen
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

        apply(code_gen, :gen_method, [name, method, args, result, doc])
      end)

    DynamicModule.gen(
      mod_name,
      preamble,
      contents,
      [{:doc, Map.get(api, "desc", "Need module doc")} | opts]
    )
  end

  defp merge_result(api_result, base_result) do
    case base_result != nil and is_binary(api_result) do
      true -> Map.get(base_result, api_result, api_result)
      _ -> api_result
    end
  end
end
