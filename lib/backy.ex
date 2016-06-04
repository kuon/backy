defmodule Backy do
  use Application

  alias Backy.Job
  alias Backy.JobStore
  alias Backy.JobRunner

  @doc """
  Enqueue a job to be run immediately
  """
  def enqueue(worker, arguments \\ []) do
    %Job{worker: worker, arguments: arguments}
    |> JobStore.persist
    |> JobRunner.run
  end

  @doc """
  Keep a job alive
  """
  def touch(%Job{} = job) do
    JobStore.touch(job)
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(JobStore, []),
      worker(JobRunner, []),
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
