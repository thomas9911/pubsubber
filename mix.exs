defmodule Pubsubber.MixProject do
  use Mix.Project

  def project do
    [
      app: :pubsubber,
      version: "0.1.0",
      elixir: "~> 1.14-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Pubsubber.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # redis
      {:redix, "~> 1.1"},
      {:castore, "~> 0.1"},
      # nats_io
      {:gnat, "~> 1.5"}
    ]
  end
end
