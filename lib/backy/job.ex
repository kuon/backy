defmodule Backy.Job do
  defstruct [id: nil, worker: nil, priority: 1, retry_count: 0, arguments: []]
end
