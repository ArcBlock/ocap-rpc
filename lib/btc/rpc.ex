defmodule OcapRpc.Internal.BtcRpc do
  @moduledoc """
  RPC request to bitcoin server
  """
  require Logger
  use Tesla

  alias OcapRpc.PoisonedDecimal

  alias OcapRpc.Converter

  plug(Tesla.Middleware.Retry, delay: 500, max_retries: 3)

  if Application.get_env(:ocap_rpc, :env) not in [:test] do
    plug(Tesla.Middleware.Timeout, timeout: 5_000)
  end

  def call(method, args) do
    config = :ocap_rpc |> Application.get_env(:btc) |> Keyword.get(:conn)
    %{hostname: hostname, port: port, user: user, password: password} = config

    body = get_body(method, args)
    headers = [{"Authorization", "Basic " <> Base.encode64(user <> ":" <> password)}]

    result =
      post(
        "http://#{hostname}:#{to_string(port)}/",
        Jason.encode!(body),
        headers: headers
      )

    case result do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"error" => nil, "id" => _, "result" => result} -> result
          %{"error" => %{"code" => code, "message" => msg}} -> handle_error(code, msg)
        end

      {:ok, %{status: code, body: body}} ->
        handle_error(code, body)
    end
  end

  @statuses %{401 => :forbidden, 404 => :notfound, 500 => :internal_server_error}

  defp handle_error(status_code, error) do
    status = @statuses[status_code]
    # Logger.debug("Bitcoin RPC error status #{status}: #{error}")

    case Jason.decode(error) do
      {:ok, %{"error" => %{"message" => message, "code" => code}}} ->
        {:error, %{status: status, error: message, code: code}}

      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, %{status: status, error: message, code: nil}}

      {:error, :invalid, _pos} ->
        {:error, %{status: status, error: error, code: nil}}

      {:error, {:invalid, _token, _pos}} ->
        {:error, %{status: status, error: error, code: nil}}
    end
  end

  def resp_hook(resp, type \\ nil) do
    case type do
      :mem_pool_transaction -> convert_map_to_list_and_append_tx_id(resp)
      :get_raw_transaction -> append_tx(resp)
      :list_address_groupings -> list_to_map_and_append_key(resp)
      :get_blockchain_info -> append_name(resp)
      _ -> resp
    end
  end

  defp convert_map_to_list_and_append_tx_id(resp) do
    Enum.map(resp, fn {key, value} -> Map.put(value, "tx_id", key) end)
  end

  defp append_tx(resp) do
    tx = call("decoderawtransaction", [resp["hex"]])
    Map.merge(tx, resp)
  end

  defp append_name(resp) do
    %{"bip9_softforks" => bip9_softforks} = resp

    case is_nil(bip9_softforks) do
      false ->
        Map.put(resp, "bip9_softforks", append_bip9_softforks_name(bip9_softforks))

      _ ->
        resp
    end
  end

  defp append_bip9_softforks_name(bip9_softforks) do
    Enum.map(bip9_softforks, fn {key, value} -> Map.put(value, "name", key) end)
  end

  defp list_to_map_and_append_key(resp) do
    resp
    |> Enum.map(fn groupings ->
      Enum.map(groupings, fn address_details ->
        convert_list_to_map(address_details)
      end)
    end)
  end

  defp convert_list_to_map(address_details) do
    [address, balance, account] = address_details

    %{}
    |> Map.put("address", address)
    |> Map.put("balance", Converter.btc_to_satoshi(balance))
    |> Map.put("account", account)
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
      params: args,
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
        params: item,
        id: idx,
        jsonrpc: "2.0"
      }
    end)
  end
end
