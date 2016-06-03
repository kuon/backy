# Backy

Simple background job backed by PostgreSQL.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add backy to your list of dependencies in `mix.exs`:

        def deps do
          [{:backy, "~> 0.0.1"}]
        end

  2. Ensure backy is started before your application:

        def application do
          [applications: [:backy]]
        end
