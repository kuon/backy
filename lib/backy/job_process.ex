defmodule Backy.JobProcess do
  @moduledoc """
    Wrapper around job which call the worker perform function.
  """

  alias Backy.Job

  def run(job) do
    case run_job(job) do
      :ok -> {:ok, job}
      error -> {:error, job, error}
    end
  end

  def touch(%Job{} = job) do
    send(job.process_pid, :touch)
    job
  end

  defp run_job(job) do
    parent = self()

    {pid, _} =
      spawn_monitor(fn ->
        send(parent, run_job_and_capture_result(%{job | process_pid: parent}))
      end)

    timer = Process.send_after(self(), :timeout, job.worker.max_runtime())
    wait_for_result(pid, job.worker.max_runtime(), timer)
  end

  defp run_job_and_capture_result(job) do
    try do
      job.worker.perform(job, job.arguments)
      :ok
    rescue
      error -> {:error, Exception.format(:error, error)}
    end
  end

  defp wait_for_result(pid, max_runtime, timer \\ nil) do
    receive do
      {:DOWN, _ref, :process, _pid, :normal} ->
        # both errors and successes result in a normal exit,
        # wait for more information
        wait_for_result(pid, max_runtime)

      {:DOWN, _ref, :process, _pid, error} ->
        Exception.format_banner(:error, error)

      {:error, error} ->
        error

      :timeout ->
        Process.exit(pid, :kill)
        wait_for_result(pid, max_runtime)

      :touch ->
        timer =
          case timer do
            nil ->
              nil

            timer ->
              Process.cancel_timer(timer)
              Process.send_after(self(), :timeout, max_runtime)
          end

        wait_for_result(pid, max_runtime, timer)

      :ok ->
        :ok
    end
  end
end
