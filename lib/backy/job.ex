defmodule Backy.Job do
  defstruct id: nil,
            worker: nil,
            retry_count: 0,
            process_pid: nil,
            arguments: []
end
