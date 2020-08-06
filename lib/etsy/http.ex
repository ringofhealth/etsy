defmodule Etsy.HTTP do
  @moduledoc """
  HTTP Client
  """

  require Logger
  alias Etsy.Env

  @simple_headers [{"content-type", "application/json"}]

  def authorization_url do
    {header, _} = oauth_headers(request_token_uri())

    response =
      :hackney.request(
        :get,
        request_token_uri(),
        List.wrap(header),
        "",
        pool: Etsy.ConnectionPool
      )
      |> handle_response()

    with {:ok, response} <- response,
         %{"login_url" => login_url} when is_binary(login_url) <-
           Regex.named_captures(~r/login_url=(?<login_url>.*)/, URI.decode(response)),
         uri = %URI{query: query} <- URI.parse(login_url),
         secret when is_binary(secret) <-
           query |> URI.decode_query() |> Map.get("oauth_token_secret"),
         "true" <- query |> URI.decode_query() |> Map.get("oauth_callback_confirmed") do
      Etsy.TokenSecretAgent.set(secret)
      {:ok, URI.to_string(uri)}
    end
  end

  def access_token(oauth_token, oauth_verifier) do
    uri = "https://openapi.etsy.com/v2/oauth/access_token"
    {header, req_params} = oauth_headers(uri, oauth_token, oauth_verifier)

    response =
      :hackney.request(
        :get,
        uri,
        List.wrap(header),
        req_params,
        pool: Etsy.ConnectionPool
      )
      |> handle_response()

    with {:ok, response} <- response,
         result = %{"oauth_token" => _, "oauth_token_secret" => _} <- URI.decode_query(response) do
      {:ok, result}
    end
  end

  def request_token_uri do
    "https://openapi.etsy.com/v2/oauth/request_token"
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{scope: Env.scopes(), oauth_callback: Env.callback()}))
    |> URI.to_string()
  end

  defp oauth_headers(url, token \\ nil, verifier \\ nil) do
    # https://oauth1.wp-api.org/docs/basics/Auth-Flow.html
    creds =
      OAuther.credentials(
        consumer_key: Env.consumer_key(),
        consumer_secret: Env.consumer_secret(),
        token: token,
        token_secret: Etsy.TokenSecretAgent.value()
      )

    extra_headers = if is_nil(verifier), do: [], else: [{"oauth_verifier", verifier}]

    "get"
    |> OAuther.sign(url, extra_headers, creds)
    |> OAuther.header()
  end

  def headers(token) when is_bitstring(token), do: [{"authorization", token} | @simple_headers]
  def headers(_), do: @simple_headers

  def handle_response(response) do
    case response do
      {:ok, code, _, ref} when is_number(code) and code >= 200 and code < 300 ->
        body(ref)

      {:ok, 401, _, ref} ->
        Logger.debug("Unauthorized HTTP response. #{inspect(:hackney.body(ref))}")
        {:error, :unauthorized}

      {:ok, status, _, ref} ->
        Logger.debug("Unhandled HTTP error. #{inspect(:hackney.body(ref))}")
        {:error, status}

      error = {:error, _type} ->
        error

      other ->
        other
    end
  end

  defp body(ref) do
    case :hackney.body(ref) do
      {:ok, body} -> {:ok, body}
      _ -> {:error, :body}
    end
  end
end
