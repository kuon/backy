use Mix.Config

if Mix.env == :test do
  config :backy, retry_delay: 10
end
