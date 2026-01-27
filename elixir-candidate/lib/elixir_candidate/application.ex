defmodule ElixirCandidate.Application do
  @moduledoc """
  Main application supervisor
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Order store (ETS-based)
      ElixirCandidate.OrderStore,
      # Dynamic supervisor for order processors
      {DynamicSupervisor, name: ElixirCandidate.OrderSupervisor, strategy: :one_for_one},
      # Chaos state manager
      ElixirCandidate.Chaos,
      # HTTP server
      {Plug.Cowboy, scheme: :http, plug: ElixirCandidate.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: ElixirCandidate.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
