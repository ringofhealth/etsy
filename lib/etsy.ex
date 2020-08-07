defmodule Etsy do
  @moduledoc """
  Main Etsy API
  """

  alias Etsy.Api

  def authorization_url, do: Api.authorization_url()

  def access_token(oauth_verifier),
    do: Api.access_token(oauth_verifier)

  def scopes, do: Api.get("/oauth/scopes")

  def call(:get, path), do: Api.get(path)
  def call(:post, path, params), do: Api.post(path, params)
end
