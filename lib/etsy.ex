defmodule Etsy do
  @moduledoc """
  Main Etsy API

  See [etsy's api documentation](https://www.etsy.com/developers/documentation/reference/listing) for
  endpoints and their corresponding parameters.
  """

  alias Etsy.Api

  @type method :: :get | :post | :put | :delete
  @type params :: list({String.t(), String.t() | float() | integer()})
  @type response :: {:ok, any()} | {:error, atom()}

  @spec authorization_url() :: {:ok, String.t()} | {:error, atom()}
  def authorization_url, do: Api.authorization_url()

  @spec access_token(String.t()) :: {:ok, map()} | {:error, atom()}
  def access_token(oauth_verifier), do: Api.access_token(oauth_verifier)

  @spec scopes() :: response()
  def scopes, do: call(:get, "/oauth/scopes")

  @spec get(String.t()) :: response()
  def get(path), do: call(:get, path)

  @spec delete(String.t()) :: response()
  def delete(path), do: call(:delete, path)

  @spec post(String.t(), params()) :: response()
  def post(path, params), do: call(:post, path, params)

  @spec put(String.t(), params()) :: response()
  def put(path, params), do: call(:put, path, params)

  @spec call(method(), String.t()) :: response()
  def call(method, path) when method in [:get, :delete], do: Api.call(method, path)
  def call(_, _), do: {:error, :not_supported}

  @spec call(method(), String.t(), params()) :: response()
  def call(method, path, params) when method in [:post, :put], do: Api.call(method, path, params)
  def call(_, _, _), do: {:error, :not_supported}
end
