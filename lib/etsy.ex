defmodule Etsy do
  @moduledoc """
  Main Etsy API
  """

  alias Etsy.Api

  def authorization_url, do: Api.authorization_url()

  def access_token(oauth_verifier), do: Api.access_token(oauth_verifier)

  def scopes, do: call(:get, "/oauth/scopes")

  def get(path), do: call(:get, path)
  def delete(path), do: call(:delete, path)

  def post(path, params), do: call(:post, path, params)
  def put(path, params), do: call(:put, path, params)

  def call(method, path) when method in [:get, :delete], do: Api.call(method, path)
  def call(_, _), do: {:error, :not_supported}

  def call(method, path, params) when method in [:post, :put], do: Api.call(method, path, params)
  def call(_, _, _), do: {:error, :not_supported}
end
