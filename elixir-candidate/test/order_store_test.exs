defmodule ElixirCandidate.OrderStoreTest do
  use ExUnit.Case, async: false

  alias ElixirCandidate.OrderStore

  setup do
    # Start the OrderStore for testing
    start_supervised!(OrderStore)
    :ok
  end

  describe "create/2" do
    test "creates an order with received status" do
      order_id = "test-order-1"
      order = OrderStore.create(order_id, %{item: "widget"})

      assert order.id == order_id
      assert order.status == :received
      assert order.retry_count == 0
      assert order.data == %{item: "widget"}
    end
  end

  describe "get/1" do
    test "retrieves an existing order" do
      order_id = "test-order-2"
      OrderStore.create(order_id)

      assert {:ok, order} = OrderStore.get(order_id)
      assert order.id == order_id
    end

    test "returns error for non-existent order" do
      assert {:error, :not_found} = OrderStore.get("non-existent")
    end
  end

  describe "update_status/2" do
    test "updates order status" do
      order_id = "test-order-3"
      OrderStore.create(order_id)

      assert {:ok, updated} = OrderStore.update_status(order_id, :processing)
      assert updated.status == :processing
    end
  end

  describe "increment_retry/1" do
    test "increments retry count" do
      order_id = "test-order-4"
      OrderStore.create(order_id)

      OrderStore.increment_retry(order_id)
      OrderStore.increment_retry(order_id)

      {:ok, order} = OrderStore.get(order_id)
      assert order.retry_count == 2
    end
  end

  describe "get_all/0" do
    test "returns all orders" do
      OrderStore.create("order-1")
      OrderStore.create("order-2")
      OrderStore.create("order-3")

      all = OrderStore.get_all()
      assert length(all) >= 3
    end
  end

  describe "stats/0" do
    test "returns statistics" do
      OrderStore.create("stat-1")
      OrderStore.create("stat-2")
      OrderStore.update_status("stat-1", :completed)

      stats = OrderStore.stats()

      assert stats.total >= 2
      assert stats.completed >= 1
      assert is_integer(stats.received)
    end
  end
end
