defmodule Etsy do
  @moduledoc """
  Main Etsy API

  See [etsy's api documentation](https://www.etsy.com/developers/documentation/reference/listing) for
  endpoints and their corresponding parameters.
  """

  alias Etsy.{Api, Credentials}

  @type method :: :get | :post | :put | :delete
  @type params :: list({String.t(), String.t() | float() | integer()})
  @type response :: {:ok, any()} | {:error, atom()}

  @spec authorization_url() :: {:ok, String.t()} | {:error, atom()}
  def authorization_url, do: Api.authorization_url()

  @spec access_token(Credentials.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def access_token(%Credentials{} = credentials, oauth_verifier),
    do: Api.access_token(credentials, oauth_verifier)

  @spec scopes(Credentials.t()) :: response()
  def scopes(%Credentials{} = credentials), do: call(:get, credentials, "/oauth/scopes")

  @spec get(Credentials.t(), String.t()) :: response()
  def get(%Credentials{} = credentials, path), do: call(:get, credentials, path)

  @spec delete(Credentials.t(), String.t()) :: response()
  def delete(%Credentials{} = credentials, path), do: call(:delete, credentials, path)

  @spec post(Credentials.t(), String.t(), params()) :: response()
  def post(%Credentials{} = credentials, path, params), do: call(:post, credentials, path, params)

  @spec put(Credentials.t(), String.t(), params()) :: response()
  def put(%Credentials{} = credentials, path, params), do: call(:put, credentials, path, params)

  @spec call(Credentials.t(), method(), String.t()) :: response()
  def call(method, %Credentials{} = credentials, path) when method in [:get, :delete],
    do: Api.call(method, credentials, path)

  def call(_, _, _), do: {:error, :not_supported}

  @spec call(Credentials.t(), method(), String.t(), params()) :: response()
  def call(method, %Credentials{} = credentials, path, params) when method in [:post, :put],
    do: Api.call(method, credentials, path, params)

  def call(_, _, _, _), do: {:error, :not_supported}
end
