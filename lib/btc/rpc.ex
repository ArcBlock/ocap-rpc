defmodule OcapRpc.Internal.BtcRpc do
  @moduledoc """
  RPC request to bitcoin server
  """
  require Logger

  def request(method, params) when is_atom(method) do
    config = Application.get_env(:ex_bitcoin, :conn)
    %{hostname: hostname, port: port, user: user, password: password} = config

    # Logger.debug("Bitcoin RPC request for method: #{method}, params: #{inspect(params)}")

    params = PoisonedDecimal.poison_params(params)

    data = %{jsonrpc: "2.0", method: to_string(method), params: params, id: 1}

    headers = [Authorization: "Basic " <> Base.encode64(user <> ":" <> password)]

    options = [timeout: 30_000, recv_timeout: 20_000]

    case HTTPoison.post(
           "http://#{hostname}:#{to_string(port)}/",
           Jason.encode!(data),
           headers,
           options
         ) do
      {:ok, %{status_code: 200, body: body}} ->
        %{"error" => nil, "result" => result} = Jason.decode!(body)
        {:ok, result}

      {:ok, %{status_code: code, body: body}} ->
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
end
