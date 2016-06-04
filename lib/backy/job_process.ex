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

  def run(job) do
    case run_job(job) do
      :ok   -> {:ok, job}
      error -> {:error, job, error}
    end
  end

  defp run_job(job) do
    parent = self

    spawn_monitor fn ->
      send(parent, run_job_and_capture_result(job))
    end

    wait_for_result
  end

  defp run_job_and_capture_result(job) do
    try do
      job.worker.perform(job, job.arguments)
      :success
    rescue
      error -> {:error, error}
    end
  end

  defp wait_for_result do
    receive do
      {:DOWN, _ref, :process, _pid, :normal} ->
        # both errors and successes result in a normal exit, wait for more information
        wait_for_result
      {:DOWN, _ref, :process, _pid, error} -> # Failed beause the process crashed
        "The job runner crashed. The reason that was given is: #{error}"
        |> wrap_in_crash_error
      {:error, error} ->
        error
      :success ->
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
