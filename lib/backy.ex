defmodule Backy do
  use Application

  alias Backy.Job
  alias Backy.JobStore
  alias Backy.JobProcess
  alias Backy.JobRunner
  alias Backy.JobPoller

  @doc """
  Enqueue a job to be run immediately. The job will be persisted and then
  queued to be run immediately on the current node.

  This function returns only after the job has been persisted.
  """
  def enqueue(worker, arguments \\ []) do
    %Job{worker: worker, arguments: arguments}
    |> JobStore.persist
    |> JobRunner.run
  end

  @doc """
  Touch a job to avoid it to timeout.

  This is intended to be called from within worker if your job is long.

  For example, you might have an encoding job that take any time to finish
  depending on the lenght of the video. You will set the `max_runtime` or the
  worker to a couple of minutes, and in your `perform` function inside
  the worker, you will call this function to extend your job lifetime.
  """
  def touch(%Job{} = job) do
    job |> JobProcess.touch |> JobStore.touch
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(JobStore, []),
      worker(JobRunner, []),
      worker(JobPoller, []),
    ]

    # Restart everything on failure
    opts = [
      strategy: :one_for_all,
      name: Backy.Supervisor,
      max_seconds: 30,
      max_restarts: 5
    ]
    Supervisor.start_link(children, opts)
  end
end
