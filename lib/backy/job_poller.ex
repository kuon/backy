defmodule Backy.JobPoller do
  use GenServer

  alias Backy.Job
  alias Backy.JobStore
  alias Backy.JobRunner
  alias Backy.JobConcurrencyLimiter

  defmodule State do
    defstruct timer: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def init(state) do
    import_jobs
    {:ok, state}
  end

  def terminate(reason, state) do
    if state.timer do
      :timer.cancel(state.timer)
    end
  end

  def handle_cast(:import_jobs, state) do
    if state.timer do
      {:ok, _} = :timer.cancel(state.timer)
    end

    drain_queue(JobStore.reserve)

    {:ok, timer} = :timer.apply_after(poll_interval, __MODULE__, :import_jobs, [])
    {:noreply, %{state | timer: timer}}
  end

  defp drain_queue(nil), do: nil
  defp drain_queue(%Job{} = job) do
    job |> JobRunner.run
    drain_queue(JobStore.reserve)
  end

  def import_jobs do
    GenServer.cast(__MODULE__, :import_jobs)
  end

  defp poll_interval do
    Application.get_env(:backy, :poll_interval)
  end


end
