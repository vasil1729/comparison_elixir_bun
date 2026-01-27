defmodule ElixirCandidate.OrderProcessor do
  @moduledoc """
  GenServer that processes a single order
  Each order runs in its own isolated process
  Supervisor automatically restarts on failure
  """
  use GenServer
  require Logger

  @max_retries 3

  # Client API

  def start_link(order_id) do
    GenServer.start_link(__MODULE__, order_id)
  end

  def process(pid) do
    GenServer.cast(pid, :process)
  end

  # Server Callbacks

  @impl true
  def init(order_id) do
    {:ok, %{order_id: order_id, retry_count: 0}}
  end

  @impl true
  def handle_cast(:process, %{order_id: order_id} = state) do
    ElixirCandidate.OrderStore.update_status(order_id, :processing)
    
    try do
      # Simulate work with potential chaos
      simulate_work(order_id)
      
      ElixirCandidate.OrderStore.update_status(order_id, :completed)
      {:stop, :normal, state}
    rescue
      error ->
        Logger.error("Order #{order_id} failed: #{inspect(error)}")
        handle_failure(state)
    end
  end

  defp handle_failure(%{order_id: order_id, retry_count: retry_count} = state) do
    if retry_count < @max_retries do
      # Increment retry count
      ElixirCandidate.OrderStore.increment_retry(order_id)
      
      Logger.info("Retrying order #{order_id} (attempt #{retry_count + 1})")
      
      # Retry after delay
      Process.sleep(1000 * (retry_count + 1))
      
      # Restart the order processor
      {:ok, pid} = DynamicSupervisor.start_child(
        ElixirCandidate.OrderSupervisor,
        {__MODULE__, order_id}
      )
      process(pid)
      
      {:stop, :normal, state}
    else
      ElixirCandidate.OrderStore.update_status(order_id, :failed)
      {:stop, :normal, state}
    end
  end

  defp simulate_work(order_id) do
    # Base processing time
    base_delay = :rand.uniform(100) + 50
    Process.sleep(base_delay)
    
    # Inject chaos if enabled
    if ElixirCandidate.Chaos.enabled?() do
      inject_chaos(order_id)
    end
  end

  defp inject_chaos(order_id) do
    case :rand.uniform() do
      x when x < 0.15 ->
        # 15% chance: Random exception
        raise "Random failure for order #{order_id}"
      
      x when x < 0.25 ->
        # 10% chance: Artificial latency (3-5 seconds)
        delay = :rand.uniform(2000) + 3000
        Logger.info("⏱️  Order #{order_id}: Injecting #{delay}ms delay")
        Process.sleep(delay)
      
      x when x < 0.30 ->
        # 5% chance: CPU-heavy task
        Logger.info("💥 Order #{order_id}: CPU-heavy task")
        cpu_intensive_task()
      
      x when x < 0.35 ->
        # 5% chance: Simulate process crash
        Logger.info("💀 Order #{order_id}: Simulating process crash")
        raise "Process crashed for order #{order_id}"
      
      _ ->
        :ok
    end
  end

  defp cpu_intensive_task do
    # CPU-intensive work (doesn't block other processes!)
    start_time = System.monotonic_time(:millisecond)
    Stream.repeatedly(fn -> :math.sqrt(:rand.uniform()) end)
    |> Enum.take_while(fn _ -> 
      System.monotonic_time(:millisecond) - start_time < 500
    end)
    |> Enum.sum()
  end
end
