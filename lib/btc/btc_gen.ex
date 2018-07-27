defmodule BlockchainRpc.Internal.BtcCodeGen do
  @moduledoc """
  Ethereum specific code generator
  """
  alias BlockchainRpc.Internal.{BtcRpc, Extractor, Parser}

  def gen_method(name, method, args, result, doc) do
    quote_rpc_call(name, args, method, result, doc)
  end

  defp quote_rpc_call(name, args, method, result, doc) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(name))(unquote_splicing(Parser.gen_args(args))) do
        args = Enum.map(binding(), fn {_, v} -> v end)

        response = BtcRpc.request(unquote(method), args)
        Extractor.process(response, unquote(Macro.escape(result)))
      end
    end
  end
end
