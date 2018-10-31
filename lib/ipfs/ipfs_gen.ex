defmodule OcapRpc.Internal.IpfsCodeGen do
  @moduledoc """
  IPFS specific code generator
  """
  alias OcapRpc.Internal.{Extractor, IpfsRpc, Parser}

  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  def gen_method(name, method, args, result, opts) do
    quote_rpc_call(name, args, method, result, opts)
  end

  defp quote_rpc_call(name, args, method, result, opts) do
    doc = Access.get(opts, :doc)
    mod_type = get_type(opts)
    verb = Access.get(opts, :verb)

    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        # need a way to know if the arg is a file and do multi part upload here
        data = binding()

        unquote(method)
        |> IpfsRpc.call(unquote(verb), data)
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
        mod_name = DynamicModule.gen_module_name(:ocap_rpc, "Eth", "Type", Recase.to_pascal(type))

        String.to_atom("Elixir.#{mod_name}")
    end
  end
end
