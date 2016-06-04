# WORK IN PROGRESS, DO NOT USE YET

# Backy

Simple background job backed by PostgreSQL for Elixir.


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

## Contributors

Copyright ©2016 [Nicolas Goy](http://github.com/kuon)

This library is loosely inspired by:

- [Toniq](https://github.com/joakimk/toniq)
- [Verk](https://github.com/edgurgel/verk)
- [Exq](https://github.com/akira/exq)

## License

MIT
