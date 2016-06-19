defmodule Backy.JobStore do
  use GenServer

  alias Backy.Job

  defmodule State do
    defstruct db: nil, table: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    config = Keyword.merge(Backy.Config.get(:db), [
      extensions: [{Postgrex.Extensions.JSON, library: Poison}]
    ])
    table = Backy.Config.get(:table_name)


    {:ok, pid} = Postgrex.start_link(config)
    {:ok, %State{db: pid, table: table}}
  end

  def persist(job, reserved \\ true)
  def persist(%Job{id: nil} = job, reserved) do
    GenServer.call(__MODULE__, {:persist, job, reserved})
  end
  def persist(%Job{}, _reserved), do: raise "job already persisted"

  def handle_call({:persist, job, reserved}, _from, %State{} = state) do
    args = normalize_args(job.arguments)
    res = Postgrex.query!(state.db,
      "INSERT INTO #{state.table}
      (worker, arguments, status, expires_at, enqueued_at)
      VALUES
      ($1, $2, $4, now() + ($3 || ' milliseconds')::INTERVAL, now())
      RETURNING id", [
      Atom.to_string(job.worker),
      args,
      Integer.to_string((job.worker.requeue_delay + job.worker.max_runtime) |> trunc),
      (if reserved, do: "reserved", else: "new")
    ])

    job = %{job | id: (res.rows |> List.first |> List.first), arguments: args}
    {:reply, job, state}
  end
  def handle_call({:mark_as_finished, job}, _from, %State{} = state) do
    if delete_finished_jobs do
      Postgrex.query!(state.db,
        "DELETE FROM #{state.table}
         WHERE id = $1::int", [job.id])
    else
      Postgrex.query!(state.db,
        "UPDATE #{state.table}
         SET finished_at = now(), status = 'finished'
         WHERE id = $1::int", [job.id])
    end
    {:reply, job, state}
  end
  def handle_call({:mark_as_failed, job, error}, _from, %State{} = state) do
    Postgrex.query!(state.db,
      "UPDATE #{state.table}
       SET failed_at = now(), status = 'failed', error = $2
       WHERE id = $1::int", [job.id, error])
    {:reply, job, state}
  end
  def handle_call({:touch, job}, _from, %State{} = state) do
    Postgrex.query!(state.db,
      "UPDATE #{state.table}
       SET expires_at = now() + ($2 || ' milliseconds')::INTERVAL
       WHERE id = $1::int", [job.id,
       Integer.to_string((job.worker.requeue_delay + job.worker.max_runtime) |> trunc)
    ])
    {:reply, job, state}
  end
  def handle_call(:reserve, _from, %State{} = state) do
    res = Postgrex.query!(state.db,
      "UPDATE #{state.table}
       SET expires_at = now() + ('1 hour')::INTERVAL, status = 'reserved'
       WHERE id IN (
         SELECT id FROM #{state.table}
         WHERE status = 'new' OR
         (status = 'reserved' AND expires_at < now())
         LIMIT 1
       )
       RETURNING id, worker, arguments",
    [])

    if res.num_rows > 0 do
      row = List.first(res.rows)
      job = try do
        args = Enum.at(row, 2) |> normalize_args
        %Job{id: Enum.at(row, 0),
                      worker: String.to_existing_atom(Enum.at(row, 1)),
                      arguments: args}
      rescue
        ArgumentError -> nil
      end
      {:reply, job, state}
    else
      {:reply, nil, state}
    end
  end

  def touch(nil), do: nil
  def touch(%Job{id: nil}), do: raise "job not persisted"
  def touch(%Job{} = job) do
    GenServer.call(__MODULE__, {:touch, job})
  end

  def reserve do
    GenServer.call(__MODULE__, :reserve) |> touch
  end

  def mark_as_finished(%Job{id: nil}), do: raise "job not persisted"
  def mark_as_finished(%Job{} = job) do
    GenServer.call(__MODULE__, {:mark_as_finished, job})
  end

  def mark_as_failed(%Job{id: nil}, _error), do: raise "job not persisted"
  def mark_as_failed(%Job{} = job, error) do
    GenServer.call(__MODULE__, {:mark_as_failed, job, error})
  end

  defp normalize_args(args) when is_list(args) do
    case Keyword.keyword?(args) do
      true -> normalize_args(Enum.into(args, %{}))
      _ -> Enum.map(args, &normalize_args/1)
    end
  end
  defp normalize_args(args) when is_map(args) do
    Enum.map(args, fn({key, value}) ->
      {normalize_key(key), normalize_args(value)}
    end) |> Enum.into(%{})
  end
  defp normalize_args(args) when is_tuple(args) do
    case Keyword.keyword?([args]) do
      true -> normalize_args(Enum.into([args], %{}))
      _ -> normalize_args(Tuple.to_list(args))
    end
  end
  defp normalize_args(args), do: args

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: normalize_key(inspect(key))

  defp delete_finished_jobs do
    Backy.Config.get(:delete_finished_jobs)
  end

end
