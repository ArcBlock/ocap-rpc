defmodule OcapRpc.Internal.CodeGen do
  @moduledoc """
  Generate RPC code based on priv/rpc/*.yml.
  """
  alias OcapRpc.Internal.{BtcCodeGen, EthCodeGen, IpfsCodeGen}
  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  def gen(rpc, result, type, opts \\ []) do
    type_name = type |> Atom.to_string() |> Recase.to_pascal()
    mod_name = DynamicModule.gen_module_name(:ocap_rpc, type_name, Map.get(rpc, "name"))

    code_gen =
      case type do
        :eth -> EthCodeGen
        :btc -> BtcCodeGen
        :ipfs -> IpfsCodeGen
        _ -> :not_implemented
      end

    preamble =
      quote do
      end

    contents =
      rpc
      |> Map.get("public")
      |> Enum.map(fn %{"name" => name, "method" => method, "args" => args} = public ->
        doc = Map.get(public, "desc", "Need public interface doc")
        rpc_result = Map.get(public, "result", nil)
        result = merge_result(rpc_result, result)
        args = Enum.map(args, &String.to_atom/1)

        type =
          case result != rpc_result do
            true -> rpc_result
            false -> nil
          end

        verb = public |> Map.get("verb", "get") |> String.to_atom()
        mapping = Enum.map(Map.get(public, "args_mapping", []), &String.to_atom/1)

        apply(code_gen, :gen_method, [
          name,
          method,
          args,
          result,
          [doc: doc, type: type, verb: verb, args_mapping: mapping]
        ])
      end)

    DynamicModule.gen(
      mod_name,
      preamble,
      contents,
      [{:doc, Map.get(rpc, "desc", "Need module doc")} | opts]
    )
  end

  def gen_type(name, fields, type, opts \\ []) do
    type_name = type |> Atom.to_string() |> Recase.to_pascal()

    preamble =
      quote do
      end

    mod_name = DynamicModule.gen_module_name(:ocap_rpc, type_name, "Type", Recase.to_pascal(name))
    mod_atom_name = String.to_atom("Elixir.#{mod_name}")

    fields = Enum.map(fields, fn {k, _} -> {k, nil} end)

    contents =
      quote do
        @derive Jason.Encoder
        defstruct unquote(fields)

        def encode(data) do
          Jason.encode!(data)
        end

        def decode(data) do
          struct(unquote(mod_atom_name), Jason.decode!(data, keys: :atoms))
        end
      end

    DynamicModule.gen(
      mod_name,
      preamble,
      contents,
      [{:doc, false} | opts]
    )
  end

  defp merge_result(rpc_result, base_result) do
    case base_result != nil and is_binary(rpc_result) do
      true -> Map.get(base_result, rpc_result, rpc_result)
      _ -> rpc_result
    end
  end
end
