defmodule OcapRpc.Internal.CmtRpc do
  @moduledoc """
  RPC request to cybermiles parity server
  """
  use Tesla
  require Logger

  # plug(Tesla.Middleware.Retry, delay: 500, max_retries: 3)

  @headers [{"content-type", "application/json"}]
  @timeout :ocap_rpc |> Application.get_env(:cmt) |> Keyword.get(:timeout)

  plug(Tesla.Middleware.Headers, @headers)

  # TODO(lei): when tesla not compatible issue solved: `https://github.com/teamon/tesla/issues/157`
  if Application.get_env(:ocap_rpc, :env) not in [:test] do
    plug(Tesla.Middleware.Timeout, timeout: Application.get_env(:ocap_rpc, :timeout, 240_000))
  end

  def call(method, args) do
    %{hostname: hostname, port: port} =
      :ocap_rpc |> Application.get_env(:cmt) |> Keyword.get(:conn)

    body = get_body(method, args)
    # Logger.debug("Cybermiles RPC request for: #{inspect(body)}}")
    result =
      post(
        "http://#{hostname}:#{to_string(port)}",
        Jason.encode!(body)
      )

    case result do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"id" => _, "result" => result} -> result
          [_ | _] = data -> process_batch_result(data)
          %{"error" => %{"code" => code, "message" => msg}} -> handle_error(code, msg)
        end

      {:error, reason} ->
        raise(
          "RPC call failed. Reason: #{inspect(reason)}, method: #{inspect(method)}, arguments: #{
            inspect(args)
          }"
        )

      # TODO: unfortunately cmt json rpc returns everything as 200, break out here as a TODO
      _ ->
        raise RuntimeError
    end
  end

  def resp_hook(resp, type \\ nil) do
    case type do
      _ -> resp
    end
  end

  defp process_batch_result(data) do
    Enum.map(data, fn %{"result" => result} -> result end)
  end

  defp get_body(method, args) do
    case is_list(List.first(args)) do
      true -> encode_many(method, args)
      _ -> encode_single(method, args)
    end
  end

  defp encode_single(method, args) do
    %{
      method: method,
      params: encode_params(args),
      id: 1,
      jsonrpc: "2.0"
    }
  end

  defp encode_many(method, args) do
    args
    |> List.first()
    |> Enum.with_index(1)
    |> Enum.map(fn {item, idx} ->
      %{
        method: method,
        params: encode_params(item),
        id: idx,
        jsonrpc: "2.0"
      }
    end)
  end

  defp encode_params(args) when is_list(args), do: Enum.map(args, &encode_params/1)

  defp encode_params(args) when is_map(args),
    do: Enum.reduce(args, %{}, fn {k, v}, acc -> Map.put(acc, k, encode_params(v)) end)

  # defp encode_params(arg) when is_integer(arg), do: Converter.to_hex(arg)
  defp encode_params("0x" <> _ = arg), do: arg
  defp encode_params(arg) when is_binary(arg), do: "0x" <> arg
  defp encode_params(arg), do: arg

  defp handle_error(code, msg) do
    Logger.error("Parity RPC error: #{code}: #{msg}")

    {:error, %{code: code, error: msg}}
  end
end
