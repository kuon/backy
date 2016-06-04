defmodule Backy.Worker do
  defmacro __using__(opts \\ []) do
    known_options = [:max_concurrency, :max_runtime]

    unknown_option = Enum.find(opts, fn ({k, _v}) ->
                                       !Enum.member?(known_options, k) end)

    if unknown_option do
      {k, _v} = unknown_option
      raise "Unknown option #{inspect(k)}. \
             Known options are #{inspect(known_options)}"
    end

    quote do
      # Delegate to perform without arguments when arguments are [],
      # you can define a perform with an argument to override this.
      def perform(job, []) do
        perform(job)
      end

      def max_concurrency do
        unquote(opts[:max_concurrency] || :unlimited)
      end

      def max_runtime do
        unquote(opts[:max_runtime] || 30)
      end

      defoverridable [perform: 2]
    end
  end
end
