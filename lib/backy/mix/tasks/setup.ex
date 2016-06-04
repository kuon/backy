defmodule Mix.Tasks.Backy.Setup do
  use Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    {[drop: drop], _, _} = args |> OptionParser.parse

    config = Keyword.merge(Application.get_env(:backy, :db), [
      extensions: [{Postgrex.Extensions.JSON, library: Poison}]
    ])

    {:ok, conn} = Postgrex.start_link(config)

    if drop do
      drop_job_table(conn)
    end
    create_job_table(conn)
  end

  def drop_job_table(conn) do
    table = Application.get_env(:backy, :table_name)
    Postgrex.query!(conn, "DROP TABLE IF EXISTS #{table}", [])
    Postgrex.query!(conn, "DROP TYPE IF EXISTS #{table}_status_type", [])
  end

  def create_job_table(conn) do
    table = Application.get_env(:backy, :table_name)
    Postgrex.query!(conn, "DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '#{table}_status_type') THEN
        CREATE TYPE #{table}_status_type AS
        ENUM ('new', 'reserved', 'failed', 'finished');
    END IF;
END$$;", [])

    Postgrex.query!(conn, "CREATE TABLE IF NOT EXISTS #{table} (\
    id serial primary key,
    worker varchar(1024) not null,
    arguments jsonb,
    enqueued_at timestamp not null,
    finished_at timestamp,
    failed_at timestamp,
    error text,
    expires_at timestamp not null,
    status #{table}_status_type not null default 'new'
    )", [])

    Postgrex.query!(conn, "CREATE INDEX ON #{table} (status)", [])
    Postgrex.query!(conn, "CREATE INDEX ON #{table} (enqueued_at)", [])
    Postgrex.query!(conn, "CREATE INDEX ON #{table} (expires_at)", [])
  end
end
