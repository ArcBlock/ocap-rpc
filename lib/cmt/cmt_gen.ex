defmodule OcapRpc.Internal.CmtCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias OcapRpc.Internal.{CmtRpc, Extractor, Parser}

  alias UtilityBelt.CodeGen.DynamicModule
  require DynamicModule

  def gen_method(name, method, args, result, opts) do
    quote_rpc_call(name, args, method, result, opts)
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
        |> CmtRpc.call(values)
        |> CmtRpc.resp_hook(unquote(action))
        |> Extractor.process(unquote(Macro.escape(result)), unquote(mod_type))
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
