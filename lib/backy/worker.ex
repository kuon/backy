defmodule Backy.Worker do
  defmacro __using__(opts \\ []) do
    known_options = [:max_concurrency, :max_runtime, :requeue_delay]

    unknown_option = Enum.find(opts, fn ({k, _v}) ->
                                       !Enum.member?(known_options, k) end)

    if unknown_option do
      {k, _v} = unknown_option
      raise "Unknown option #{inspect(k)}. \
             Known options are #{inspect(known_options)}"
    end

    quote do
      # Delegate perform
      def perform(job, []) do
        perform(job)
      end

      def perform(job, nil) do
        perform(job)
      end

      def perform(job) do
      end

      def max_concurrency do
        unquote(opts[:max_concurrency] || :unlimited)
      end

      def max_runtime do
        unquote(opts[:max_runtime] || 1000)
      end

      def requeue_delay do
        unquote(opts[:requeue_delay] || 10000)
      end

      defoverridable [perform: 1]
    end
  end
end
