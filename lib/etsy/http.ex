defmodule Etsy.HTTP do
  @moduledoc """
  HTTP Client
  """

  require Logger
  alias Etsy.Env

  def call(method, uri, headers) when method in [:get, :delete] do
    request(method, uri, List.wrap(headers), "")
  end

  def call(_, _, _), do: {:error, :bad_method}

  def call(method, uri, headers, params) when method in [:post, :put] do
    request(
      method,
      uri,
      List.wrap(headers),
      {:form, params}
    )
  end

  def call(_, _, _, _), do: {:error, :bad_method}

  defp request(method, uri, headers, body) when method in [:get, :put, :post, :delete] do
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

  def sign(method, url, options \\ [])

  def sign(method, url, options) when method in ["get", "put", "post", "delete"] do
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

    {:ok,
     method
     |> OAuther.sign(url, params, creds)
     |> OAuther.header()}
  end

  def sign(_, _, _), do: {:error, :bad_method}

  defp handle_response(response) do
    case response do
      {:ok, code, headers, ref} when is_number(code) and code >= 200 and code < 300 ->
        body(headers, ref)

      {:ok, 401, _, ref} ->
        Logger.warn("Unauthorized HTTP response. #{inspect(:hackney.body(ref))}")
        {:error, :unauthorized}

      {:ok, 403, _, ref} ->
        Logger.warn("Forbidden HTTP response. #{inspect(:hackney.body(ref))}")
        {:error, :forbidden}

      {:ok, status, _, ref} ->
        Logger.warn("Unhandled HTTP error. #{inspect(:hackney.body(ref))}")
        {:error, status}

      error = {:error, _type} ->
        error

      other ->
        Logger.warn("Unknown error. #{inspect(other)}")
        {:error, :unknown}
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
