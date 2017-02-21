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

  def get(:db = key) do
    config = Application.get_env(:backy, key, Map.get(default_config(), key))
    {url, config} = Keyword.pop(config, :url)
    Keyword.merge(config, parse_url(url))
    |> IO.inspect
  end

  def get(key) do
    Application.get_env(:backy, key, Map.get(default_config(), key))
  end

  # This is copied from Ecto as postgrex don't support this natively
  def parse_url(""), do: []

  def parse_url(nil), do: []

  def parse_url({:system, env}) when is_binary(env) do
    parse_url(System.get_env(env) || "")
  end

  def parse_url(url) when is_binary(url) do
    info = url |> URI.decode() |> URI.parse()

    if is_nil(info.host) do
      raise Backy.InvalidURLError, url: url, message: "host is not present"
    end

    if is_nil(info.path) or not (info.path =~ ~r"^/([^/])+$") do
      raise Backy.InvalidURLError, url: url, message: "path should be a database name"
    end

    destructure [username, password], info.userinfo && String.split(info.userinfo, ":")
    "/" <> database = info.path

    opts = [username: username,
            password: password,
            database: database,
            hostname: info.host,
            port:     info.port]

    Enum.reject(opts, fn {_k, v} -> is_nil(v) end)
  end
end
