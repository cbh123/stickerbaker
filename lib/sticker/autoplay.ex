defmodule Sticker.Autoplay do
  use GenServer

  alias Sticker.Predictions
  alias Phoenix.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{activated: true}, name: __MODULE__)
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  # Public API to activate the worker
  def activate do
    IO.puts("Activating Autoplay")
    GenServer.cast(__MODULE__, :activate)
  end

  # Public API to deactivate the worker
  def deactivate do
    GenServer.cast(__MODULE__, :deactivate)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.activated, state}
  end

  # Handles the :activate message
  def handle_cast(:activate, state) do
    new_state = Map.put(state, :activated, true)
    schedule_work_if_activated(new_state)
    {:noreply, new_state}
  end

  # Handles the :deactivate message
  def handle_cast(:deactivate, state) do
    {:noreply, Map.put(state, :activated, false)}
  end

  # Schedules work if activated
  defp schedule_work_if_activated(%{activated: true} = state) do
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work_if_activated(response), do: response

  def handle_info(:work, %{activated: true} = state) do
    update_and_broadcast_oldest_prediction()
    {:noreply, state}
  end

  def handle_info(:work, state), do: {:noreply, state}

  defp schedule_work() do
    amount_of_time = Enum.random(1000..10_000)
    Process.send_after(self(), :work, amount_of_time)
  end

  defp update_and_broadcast_oldest_prediction() do
    Predictions.get_oldest_safe_prediction()
    |> case do
      nil ->
        :ok

      prediction ->
        current_time = DateTime.utc_now()

        {:ok, prediction} =
          Predictions.update_prediction(prediction, %{autoplay_time: current_time})

        PubSub.broadcast(
          Sticker.PubSub,
          "safe-prediction-firehose",
          {:new_prediction, prediction}
        )

        schedule_work()
    end
  end
end
