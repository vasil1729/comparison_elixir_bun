defmodule ElixirCandidate.Router do
  @moduledoc """
  HTTP router using Plug
  Implements the same API as the Bun baseline
  """
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  # POST /orders - Create new order
  post "/orders" do
    order_id = UUID.uuid4()
    data = conn.body_params

    # Create order in store
    ElixirCandidate.OrderStore.create(order_id, data)

    # Start order processor in supervised process
    {:ok, pid} = DynamicSupervisor.start_child(
      ElixirCandidate.OrderSupervisor,
      {ElixirCandidate.OrderProcessor, order_id}
    )

    # Start processing
    ElixirCandidate.OrderProcessor.process(pid)

    send_json(conn, 200, %{
      order_id: order_id,
      status: "received"
    })
  end

  # GET /orders/:id - Get order status
  get "/orders/:id" do
    case ElixirCandidate.OrderStore.get(id) do
      {:ok, order} ->
        send_json(conn, 200, %{
          order_id: order.id,
          status: Atom.to_string(order.status),
          created_at: DateTime.to_iso8601(order.created_at),
          updated_at: DateTime.to_iso8601(order.updated_at),
          retry_count: order.retry_count
        })

      {:error, :not_found} ->
        send_json(conn, 404, %{error: "Order not found"})
    end
  end

  # POST /chaos - Enable chaos mode
  post "/chaos" do
    ElixirCandidate.Chaos.enable()

    send_json(conn, 200, %{
      message: "Chaos mode enabled",
      warning: "Random failures will now occur during order processing"
    })
  end

  # GET /health - Health check
  get "/health" do
    supervisor_count = DynamicSupervisor.count_children(ElixirCandidate.OrderSupervisor)

    send_json(conn, 200, %{
      status: "ok",
      runtime: "elixir",
      active_processors: supervisor_count.active
    })
  end

  # GET /stats - System statistics
  get "/stats" do
    stats = ElixirCandidate.OrderStore.stats()
    supervisor_count = DynamicSupervisor.count_children(ElixirCandidate.OrderSupervisor)

    send_json(conn, 200, Map.merge(stats, %{
      active_processors: supervisor_count.active
    }))
  end

  # Catch-all
  match _ do
    send_json(conn, 404, %{error: "Not found"})
  end

  # Helper functions

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end

# Simple UUID generator (avoiding external dependency)
defmodule UUID do
  def uuid4 do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    |> Base.encode16(case: :lower)
    |> format_uuid()
  end

  defp format_uuid(<<p1::binary-8, p2::binary-4, p3::binary-4, p4::binary-4, p5::binary-12>>) do
    "#{p1}-#{p2}-#{p3}-#{p4}-#{p5}"
  end
end
