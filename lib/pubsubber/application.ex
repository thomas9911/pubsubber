defmodule Pubsubber.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # %{
        #   id: Pubsubber.Backend,
        #   start: {Pubsubber.Backend, :start_link, [Application.get_all_env(:pubsubber)]}
        # }
      ]
      |> Enum.concat(Pubsubber.Backend.start_children(Application.get_all_env(:pubsubber)))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pubsubber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
