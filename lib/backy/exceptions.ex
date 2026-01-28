defmodule Backy.InvalidURLError do
  defexception [:message, :url]

  def exception(opts) do
    url = Keyword.fetch!(opts, :url)
    msg = Keyword.fetch!(opts, :message)
    msg = "invalid url #{url}, #{msg}"
    %__MODULE__{message: msg, url: url}
  end
end
