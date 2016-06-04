defmodule BackyTest do
  use ExUnit.Case
  doctest Backy

  defmodule TestWorker do
    use Backy.Worker

    def perform(%Backy.Job{}, name: name) do
      send :backy_test, { :job_has_been_run, name_was: name }
    end
  end

  setup do
    Process.register(self, :backy_test)
    :ok
  end

  test "enqueuing jobs" do
    job = Backy.enqueue(TestWorker, name: "Jon Doe")

    assert(job.id)

    assert_receive { :job_has_been_run, name_was: "Jon Doe" }
    #assert_receive { :finished, ^job }

    #:timer.sleep 1 # allow persistence some time to remove the job
    #assert Toniq.JobPersistence.jobs == []
  end
end
