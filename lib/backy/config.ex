defmodule Backy.Config do
  defp default_config do
    %{
      table_name: "jobs",
      retry_count: 3,
      retry_delay: fn (retry) -> :math.pow(retry, 3) + 100 end,
      poll_interval: 1000,
      delete_finished_jobs: true,
      db: [database: "backy"]
    }
  end

  def get(key) do
    Application.get_env(:backy, key, Map.get(default_config(), key))
  end
end
