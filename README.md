# Backy

Simple background job backed by PostgreSQL for Elixir.

**NOTE**: Backy is still in very early stage of development and might not be
stable yet.

[API Doc](https://hexdocs.pm/backy/api-reference.html)

## Installation

The package can be installed as:

1. Add backy to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:backy, "~> 0.0.16"}]
end
```

2. Ensure backy is started before your application:

```elixir
def application do
  [applications: [:backy]]
end
```

## Configuration

### Database configuration

In your `config.exs`:

```elixir
# Default configuration
config :backy, :db,
  database: "backy"
```

The `:db` hash is passed directly to `Postgrex.start_link/1`
( https://hexdocs.pm/postgrex/Postgrex.html#start_link/1 ).
You can specify any supported option

### Backy configuration

```elixir
# Default configuration
config :backy,
  table_name: "jobs", # The postgresql table name
  retry_count: 3, # The number of retry for a job before marking it as failed
  retry_delay: fn (retry) -> :math.pow(retry, 3) + 100 end, # Retry delay
  poll_interval: 1000, # Polling interval for the job poller
  # If false, jobs will be marked as finished, otherwise they are deleted
  # If false, you are responsible for purging the jobs table
  delete_finished_jobs: true
```

## Setup

To create the job table, run:

```
mix backy.setup
```

### Ecto/Phoenix configuration

If you use backy with ecto/phoenix, you may include backy mix tasks
in `ecto.reset` like so:

```elixir
defp aliases do
  ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
   "test": ["ecto.create --quiet", "ecto.migrate", "test"],
   "ecto.reset": ["ecto.drop", "ecto.create", "backy.setup", "ecto.setup"]]
end
```

## Writing a worker

IMPORTANT: Jobs will always receive maps instead of keyword list, because of
JSON serialization, the order of key is not guaranteed, for this reason
all the keyword lists are converted to maps.

```elixir
defmodule TestWorker do
  use Backy.Worker,
      # If the job `perform` takes more than 20 sec, kill it
      # default to 1000 (1sec)
      max_runtime: 20000,
      # Max concurrency, default to `:unlimited`
      max_concurrency: 2,
      # When a job is stuck (for example, beam crashed), wait 10 sec before
      # queuing it again, default to 10000 (10sec)
      requeue_delay: 20000


  # The following example runs for 30 sec while the max runtime is 20 sec
  def perform(%Backy.Job{} = job, %{name: name}) do
    IO.puts("Job started for #{name}")
    :timer.sleep(10000) # Simulate work for 10 sec
    # We have still work to do, max runtime is 20sec, avoid a timeout
    Backy.touch(job)
    :timer.sleep(10000) # Simulate work for 10 sec
    # We have still work to do, max runtime is 20sec, avoid a timeout
    Backy.touch(job)
    :timer.sleep(10000) # Simulate work for 10 sec
    IO.puts("Job finished")
  end

end
```

## Enqueuing jobs

```elixir
job = Backy.enqueue(TestWorker, name: "foo bar")
```

## Contributors

Copyright ©2016 [Nicolas Goy](http://github.com/kuon)

This library is loosely inspired by:

- [Toniq](https://github.com/joakimk/toniq)
- [Verk](https://github.com/edgurgel/verk)
- [Exq](https://github.com/akira/exq)

## License

MIT
