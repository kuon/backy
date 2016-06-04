# Initial version of this file:
#
# Copyright (c) 2015 Joakim Kolsjö - https://github.com/joakimk/toniq
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

defmodule Backy.JobProcess do
  @moduledoc """
    Wrapper around job which call the worker perform function.
  """

  alias Backy.Job

  def run(job) do
    case run_job(job) do
      :ok   -> {:ok, job}
      error -> {:error, job, error}
    end
  end

  def touch(%Job{} = job) do
    send(job.process_pid, :touch)
    job
  end

  defp run_job(job) do
    parent = self

    {pid, _} = spawn_monitor fn ->
      send(parent, run_job_and_capture_result(%{job | process_pid: parent}))
    end

    {:ok, timer} = :timer.send_after(job.worker.max_runtime, :timeout)
    wait_for_result(pid, job.worker.max_runtime, timer)
  end

  defp run_job_and_capture_result(job) do
    try do
      job.worker.perform(job, job.arguments)
      :ok
    rescue
      error ->

      IO.inspect(error)
        {:error, error}
    end
  end

  defp wait_for_result(pid, max_runtime, timer \\ nil) do
    receive do
      {:DOWN, _ref, :process, _pid, :normal} ->
        # both errors and successes result in a normal exit, wait for more information
        wait_for_result(pid, max_runtime)
      {:DOWN, _ref, :process, _pid, error} -> # Failed beause the process crashed
        "job runner crashed: #{error}"
        |> wrap_in_crash_error
      {:error, error} ->
        error
      :timeout ->
        Process.exit(pid, :kill)
        wait_for_result(pid, max_runtime)
      :touch ->
        :timer.cancel(timer)
        {:ok, timer} = :timer.send_after(max_runtime, :timeout)
        wait_for_result(pid, max_runtime, timer)
      :ok ->
        :ok
    end
  end

  defmodule CrashError do
    @moduledoc """
      Represents a process crash. Ensures we always return an error struct,
      even if the crash didn't occur from a raised error.

      Keeps the consuming code simple.
    """

    defstruct message: ""
  end

  defp wrap_in_crash_error(message) do
    %CrashError{message: message}
  end
end
