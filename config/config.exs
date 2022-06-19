import Config

config :pubsubber,
  backends: [
    redis: %{
      url: "redis://localhost:6379/1"
    },
    nats: %{host: "127.0.0.1", port: 4222}
  ]

config :pubsubber, backend: :nats
