defmodule ElixirCandidate.Chaos do
  @moduledoc """
  Chaos engineering state manager
  """
  use GenServer

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, false, name: __MODULE__)
  end

  def enable do
    GenServer.call(__MODULE__, :enable)
  end

  def enabled? do
    GenServer.call(__MODULE__, :enabled?)
  end

  # Server Callbacks

  @impl true
  def init(enabled) do
    {:ok, enabled}
  end

  @impl true
  def handle_call(:enable, _from, _state) do
    IO.puts("🔥 CHAOS MODE ENABLED")
    {:reply, :ok, true}
  end

  @impl true
  def handle_call(:enabled?, _from, state) do
    {:reply, state, state}
  end
end
