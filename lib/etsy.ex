defmodule Etsy do
  @moduledoc """
  Main Etsy API
  """

  alias Etsy.Api

  def authorization_url, do: Api.authorization_url()

  def access_token(oauth_verifier),
    do: Api.access_token(oauth_verifier)

  def scopes, do: Api.scopes()
end
