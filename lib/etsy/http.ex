defmodule Etsy.HTTP do
  @moduledoc """
  HTTP Client
  """

  require Logger
  alias Etsy.Env

  def get(uri, headers) do
    request(:get, uri, [{"content-type", "application/json"} | List.wrap(headers)], "")
  end

  def post(uri, headers, body) do
    request(
      :post,
      uri,
      [{"content-type", "application/x-www-form-urlencoded"} | List.wrap(headers)],
      body
    )
  end

  def put(uri, headers, body) do
    request(
      :put,
      uri,
      [{"content-type", "application/x-www-form-urlencoded"} | List.wrap(headers)],
      body
    )
  end

  defp request(method, uri, headers, body) when method in [:get, :put, :post] do
    handle_response(
      :hackney.request(
        method,
        uri,
        headers,
        body,
        pool: Etsy.ConnectionPool
      )
    )
  end

  def oauth_headers(method, url, options \\ [])
  def oauth_headers(:get, url, options), do: oauth_headers("get", url, options)
  def oauth_headers(:post, url, options), do: oauth_headers("post", url, options)
  def oauth_headers(:put, url, options), do: oauth_headers("put", url, options)

  def oauth_headers(method, url, options) when method in ["get", "post"] do
    # https://oauth1.wp-api.org/docs/basics/Auth-Flow.html
    creds =
      OAuther.credentials(
        consumer_key: Env.consumer_key(),
        consumer_secret: Env.consumer_secret(),
        token: Etsy.TokenStore.token(),
        token_secret: Etsy.TokenStore.token_secret()
      )

    params =
      cond do
        Keyword.has_key?(options, :verifier) ->
          [{"oauth_verifier", Keyword.get(options, :verifier)}]

        Keyword.has_key?(options, :params) ->
          Keyword.get(options, :params)

        true ->
          []
      end

    method
    |> OAuther.sign(url, params, creds)
    |> OAuther.header()
  end

  def oauth_headers(_, _, _), do: {:error, :oauth_headers}

  def handle_response(response) do
    case response do
      {:ok, code, headers, ref} when is_number(code) and code >= 200 and code < 300 ->
        body(headers, ref)

      {:ok, 401, _, ref} ->
        Logger.debug("Unauthorized HTTP response. #{inspect(:hackney.body(ref))}")
        {:error, :unauthorized}

      {:ok, status, _, ref} ->
        Logger.warn("Unhandled HTTP error. #{inspect(:hackney.body(ref))}")
        {:error, status}

      error = {:error, _type} ->
        error

      other ->
        Logger.warn("Unknown error. #{inspect(other)}")
        {:error, :handle_response}
    end
  end

  defp body(headers, ref) do
    if json?(headers) do
      with {:body, {:ok, body}} <- {:body, :hackney.body(ref)},
           {:decode, {:ok, decoded}} <- {:decode, Jason.decode(body)} do
        {:ok, decoded}
      else
        error ->
          Logger.error("Error json decoding body. #{inspect(error)}")
          {:error, :body}
      end
    else
      case :hackney.body(ref) do
        {:ok, body} ->
          {:ok, body}

        error ->
          Logger.error("Error text decoding body. #{inspect(error)}")
          {:error, :body}
      end
    end
  end

  defp json?(headers) when is_list(headers) do
    Enum.any?(headers, fn {_key, value} -> String.downcase(value) == "application/json" end)
  end

  defp json?(_), do: false
end
