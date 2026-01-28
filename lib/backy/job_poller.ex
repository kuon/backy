defmodule Backy.JobPoller do
  use GenServer

  alias Backy.Job
  alias Backy.JobStore
  alias Backy.JobRunner

  defmodule State do
    defstruct timer: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def start_link(_args) do
    start_link()
  end

  @impl true
  def init(state) do
    {:ok, %{state | timer: schedule_next_import()}}
  end

  defp schedule_next_import do
    {:ok, timer} =
      :timer.apply_after(poll_interval(), __MODULE__, :import_jobs, [])

    timer
  end

  @impl true
  def terminate(_reason, state) do
    if state.timer do
      :timer.cancel(state.timer)
    end
  end

  @impl true
  def handle_cast(:import_jobs, state) do
    if state.timer do
      {:ok, _} = :timer.cancel(state.timer)
    end

    drain_queue(JobStore.reserve())

    {:ok, timer} =
      :timer.apply_after(poll_interval(), __MODULE__, :import_jobs, [])

    {:noreply, %{state | timer: timer}}
  end

  defp drain_queue(nil), do: nil

  defp drain_queue(%Job{} = job) do
    job |> JobRunner.run()
    drain_queue(JobStore.reserve())
  end

  def import_jobs do
    GenServer.cast(__MODULE__, :import_jobs)
  end

  defp poll_interval do
    Backy.Config.get(:poll_interval)
  end
end
