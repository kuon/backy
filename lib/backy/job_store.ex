defmodule Backy.JobStore do
  use GenServer

  alias Backy.Job

  defmodule State do
    defstruct db: nil, table: nil
  end

  def start_link do
    config = Keyword.merge(Application.get_env(:backy, :db), [
      extensions: [{Postgrex.Extensions.JSON, library: Poison}]
    ])
    table_name = Application.get_env(:backy, :table_name)

    {:ok, pid} = Postgrex.start_link(config)
    GenServer.start_link(__MODULE__, %State{db: pid, table: table_name}, name: __MODULE__)
  end


  def persist(%Job{id: nil} = job) do
    GenServer.call(__MODULE__, {:persist, job})
  end
  def persist(%Job{}), do: raise "job already persisted"

  def handle_call({:persist, job}, _from, %State{} = state) do
    res = Postgrex.query!(state.db,
      "INSERT INTO #{state.table} \
      (worker, arguments, status, expires_at, enqueued_at) \
      VALUES \
      ($1, $2, 'reserved', now() + ($3 || ' seconds')::INTERVAL, now()) \
      RETURNING id", [
      Atom.to_string(job.worker),
      Enum.into(job.arguments, %{}),
      Integer.to_string(job.worker.max_runtime |> trunc)
    ])

    job = %{job | id: res.rows |> List.first |> List.first}
    {:reply, job, state}
  end
  def handle_call({:mark_as_finished, job}, _from, %State{} = state) do
    Postgrex.query!(state.db,
      "UPDATE #{state.table} \
       SET finished_at = now(), status = 'finished' \
       WHERE id = $1::int", [job.id])
    {:reply, job, state}
  end
  def handle_call({:mark_as_failed, job, error}, _from, %State{} = state) do
    Postgrex.query!(state.db,
      "UPDATE #{state.table} \
       SET failed_at = now(), status = 'failed', error = $2 \
       WHERE id = $1::int", [job.id, error.message])
    {:reply, job, state}
  end

  def touch(%Job{id: nil}), do: raise "job not persisted"
  def touch(%Job{} = job) do
    job
  end

  def mark_as_finished(%Job{id: nil}), do: raise "job not persisted"
  def mark_as_finished(%Job{} = job) do
    GenServer.call(__MODULE__, {:mark_as_finished, job})
  end

  def mark_as_failed(%Job{id: nil}, _error), do: raise "job not persisted"
  def mark_as_failed(%Job{} = job, error) do
    GenServer.call(__MODULE__, {:mark_as_failed, job, error})
  end

end
