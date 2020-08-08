defmodule Etsy.Api do
  @moduledoc """
  Etsy Api
  """
  require Logger
  alias Etsy.{Credentials, Env, HTTP}
  @access_token_uri "https://openapi.etsy.com/v2/oauth/access_token"
  @request_token_uri "https://openapi.etsy.com/v2/oauth/request_token"

  def authorization_url do
    with {:sign, {:ok, {headers, _}}} <- {:sign, HTTP.sign("get", request_token_uri())},
         {:request, {:ok, body}} <- {:request, HTTP.call(:get, request_token_uri(), headers)},
         {:login_url, {:ok, login_url}} <- {:login_url, get_login_url(body)},
         {:parse_uri, {:ok, uri = %URI{query: query}}} <- {:parse_uri, parse_uri(login_url)},
         {:decode,
          {:ok,
           %{
             "oauth_token" => token,
             "oauth_token_secret" => token_secret,
             "oauth_callback_confirmed" => confirmed?
           }}} <- {:decode, decode_query_params(query)},
         {:confirmed, "true"} <- {:confirmed, confirmed?} do
      {:ok, {Credentials.new(token: token, secret: token_secret), URI.to_string(uri)}}
    else
      error ->
        Logger.error("Error getting authorization_url. error: #{inspect(error)}")
        {:error, :authorization_url}
    end
  end

  def access_token(%Credentials{} = credentials, oauth_verifier) do
    with {:sign, {:ok, {headers, _}}} <-
           {:sign, HTTP.sign("get", credentials, @access_token_uri, verifier: oauth_verifier)},
         {:request, {:ok, body}} <- {:request, HTTP.call(:get, @access_token_uri, headers)},
         {:decode, %{"oauth_token" => oauth_token, "oauth_token_secret" => oauth_token_secret}} <-
           {:decode, URI.decode_query(body)} do
      {:ok, Credentials.new(token: oauth_token, secret: oauth_token_secret)}
    end
  end

  def call(method, %Credentials{} = credentials, path) when method in [:get, :delete] do
    case HTTP.sign(Atom.to_string(method), credentials, uri(path)) do
      {:ok, {header, _}} ->
        HTTP.call(method, uri(path), header)

      error ->
        Logger.error("Error calling Etsy.Api.call/2. error: #{inspect(error)}")
    end
  end

  def call(_, _, _), do: {:error, :call}

  def call(method, %Credentials{} = credentials, path, params) when method in [:post, :put] do
    case HTTP.sign(Atom.to_string(method), credentials, uri(path), params: params) do
      {:ok, {header, params}} ->
        HTTP.call(method, uri(path), header, params)

      error ->
        Logger.error("Error calling Etsy.Api.call/2. error: #{inspect(error)}")
    end
  end

  def call(_, _, _, _), do: {:error, :call}

  defp uri(path), do: Env.base_uri() <> path

  defp get_login_url(body) do
    case Regex.named_captures(~r/login_url=(?<login_url>.*)/, URI.decode(body)) do
      %{"login_url" => login_url} -> {:ok, login_url}
      _ -> {:error, :login_url}
    end
  end

  defp parse_uri(uri) do
    case URI.parse(uri) do
      parsed = %URI{
        authority: "www.etsy.com",
        host: "www.etsy.com",
        scheme: "https"
      } ->
        {:ok, parsed}

      _ ->
        {:error, :query_params}
    end
  end

  defp decode_query_params(query) do
    map = URI.decode_query(query)
    keys = Map.keys(map)

    if ~w(oauth_callback oauth_callback_confirmed oauth_consumer_key oauth_token oauth_token_secret service)
       |> Enum.all?(fn key -> Enum.member?(keys, key) end) do
      {:ok, map}
    else
      {:error, :missing_key}
    end
  end

  defp request_token_uri do
    @request_token_uri
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{scope: Env.scopes(), oauth_callback: Env.callback()}))
    |> URI.to_string()
  end
end
