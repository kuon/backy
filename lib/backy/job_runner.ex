defmodule Backy.JobRunner do
  use GenServer

  alias Backy.Job
  alias Backy.JobStore
  alias Backy.JobConcurrencyLimiter

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def run(%Job{id: nil}), do: raise "cannot run non persisted job"

  def run(%Job{} = job) do
    GenServer.cast(__MODULE__, {:run, job})
    job
  end

  def handle_cast({:run, job}, state) do
    spawn_link fn ->
      job
      |> run_job
      |> retry_job
      |> process_result
    end

    {:noreply, state}
  end

  defp run_job(job), do: JobConcurrencyLimiter.run(job)

  defp retry_job(result), do: retry_job(result, 1)
  defp retry_job({:ok, job}, _retry), do: {:ok, job}
  defp retry_job({:error, job, error}, retry) do
    if retry <= retry_count() do
      retry_delay(retry)
      |> trunc
      |> :timer.sleep

      job
      |> run_job
      |> retry_job(retry + 1)
    else
      {:error, job, error}
    end
  end

  defp process_result({:ok, job}) do
    JobStore.mark_as_finished(job)
  end

  defp process_result({:error, job, error}) do
    JobStore.mark_as_failed(job, error)
  end

  defp retry_delay(retry) do
    delay = Backy.Config.get(:retry_delay)
    if is_function(delay) do
      delay.(retry)
    else
      delay
    end
  end

  defp retry_count do
    Backy.Config.get(:retry_count)
  end

end
