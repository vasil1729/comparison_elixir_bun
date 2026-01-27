defmodule ElixirCandidate.OrderStore do
  @moduledoc """
  ETS-based order state management
  Each order is stored with its status and metadata
  """
  use GenServer

  @table_name :orders

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create(order_id, data \\ %{}) do
    order = %{
      id: order_id,
      status: :received,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      retry_count: 0,
      data: data
    }
    :ets.insert(@table_name, {order_id, order})
    order
  end

  def get(order_id) do
    case :ets.lookup(@table_name, order_id) do
      [{^order_id, order}] -> {:ok, order}
      [] -> {:error, :not_found}
    end
  end

  def update_status(order_id, status) do
    case get(order_id) do
      {:ok, order} ->
        updated_order = %{order | status: status, updated_at: DateTime.utc_now()}
        :ets.insert(@table_name, {order_id, updated_order})
        {:ok, updated_order}
      error -> error
    end
  end

  def increment_retry(order_id) do
    case get(order_id) do
      {:ok, order} ->
        updated_order = %{order | retry_count: order.retry_count + 1}
        :ets.insert(@table_name, {order_id, updated_order})
        {:ok, updated_order}
      error -> error
    end
  end

  def get_all do
    :ets.tab2list(@table_name)
    |> Enum.map(fn {_id, order} -> order end)
  end

  def stats do
    orders = get_all()
    %{
      total: length(orders),
      received: Enum.count(orders, &(&1.status == :received)),
      processing: Enum.count(orders, &(&1.status == :processing)),
      completed: Enum.count(orders, &(&1.status == :completed)),
      failed: Enum.count(orders, &(&1.status == :failed))
    }
  end

  # Server Callbacks

  @impl true
  def init(:ok) do
    :ets.new(@table_name, [:named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
