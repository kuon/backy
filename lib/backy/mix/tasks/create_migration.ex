defmodule Mix.Tasks.Backy.CreateMigration do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Create an ecto migration for the backy table"
  @moduledoc """
  This is an alternative to `mix backy.setup`. Instead of creating the backy
  table directly, this task generates an Ecto migration you can
  use in your project.

  Usage (with defaults):

      mix backy.create_migration --path=priv/repo/migrations/ \
                                 --name=backy_setup \
                                 --repo=MyApp.Repo \
                                 --table=jobs
  """

  def run(args) do
    {opts, _, _} =
      args
      |> OptionParser.parse(
        strict: [path: :string, name: :string, jobs: :string, repo: :string]
      )

    path =
      (opts[:path] || "priv/repo/migrations/")
      |> Path.expand(File.cwd!())

    name = Macro.underscore(opts[:name] || "backy_setup")

    repo = opts[:repo] || "MyApp.Repo"

    file = Path.join(path, "#{timestamp()}_#{name}.exs")

    table = opts[:jobs] || "jobs"
    mod = Module.concat([repo, Migrations, Macro.camelize(name)])

    data = migration_template(table: table, mod: mod)

    create_file(file, data)
  end

  # From Ecto
  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration

    def up do

      execute "CREATE TYPE <%= @table %>_status_type AS ENUM ('new', 'reserved', 'failed', 'finished')"

      create table(:<%= @table %>) do

        add :status, :<%= @table %>_status_type, null: false, default: "new"

        add :worker, :string, size: 1024, null: false
        add :arguments, :jsonb

        add :error, :string, size: 128000

        add :enqueued_at, :datetime, null: false
        add :finished_at, :datetime
        add :failed_at, :datetime
        add :expires_at, :datetime, null: false

      end
      create index(:<%= @table %>, [:status])
      create index(:<%= @table %>, [:enqueued_at])
      create index(:<%= @table %>, [:expires_at])
    end

    def down do
      drop table(:<%= @table %>)
      execute "DROP TYPE <%= @table %>_status_type"
    end
  end
  """)
end
