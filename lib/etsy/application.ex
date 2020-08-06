defmodule Etsy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Etsy.Env

  def start(_type, _args) do
    children = [
      :hackney_pool.child_spec(Etsy.ConnectionPool,
        timeout: Env.timeout(),
        max_connections: Env.max_connections()
      ),
      Etsy.TokenSecretAgent
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Etsy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
