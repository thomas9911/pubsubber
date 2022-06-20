defmodule Pubsubber.Backend do
  @moduledoc """
  Pubsub backend abstraction, this has two proccesses one for publishing and one for subscribing
  """
  alias Pubsubber.Backend.GenServer
  alias Pubsubber.Backend.Redis
  alias Pubsubber.Backend.Nats

  @callback subscribe(conn :: pid, send_to :: pid, topic :: binary) :: {:ok, any}
  @callback unsubscribe(conn :: pid, send_to :: pid, topic :: binary) :: {:ok, any}
  @callback publish(conn :: pid, topic :: binary, message :: binary) :: {:ok, any}
  @callback extract_message(response :: any) :: binary

  @ets_table :pubsubber_backend

  def start_link(function, args \\ []) when function in [:publisher, :subscriber] do
    backend = Keyword.get(args, :backend)
    backend_module = get_backend_module(backend)
    config = get_config(backend)

    new_ets_or_reuse(@ets_table, [:named_table, :set, :protected, {:read_concurrency, true}])

    case backend_module.start_link(function, config) do
      {:ok, pid} ->
        :ets.insert(@ets_table, {function, {backend_module, pid}})
        {:ok, pid}

      error ->
        error
    end
  end

  def start_children(args \\ []) do
    [
      %{
        id: Pubsubber.Backend.Publisher,
        start: {Pubsubber.Backend, :start_link, [:publisher, args]}
      },
      %{
        id: Pubsubber.Backend.Subscriber,
        start: {Pubsubber.Backend, :start_link, [:subscriber, args]}
      }
    ]
  end

  defp get_backend_module(:redis), do: Redis
  defp get_backend_module(:nats), do: Nats
  defp get_backend_module(:gen_server), do: GenServer
  defp get_backend_module(_), do: Redis

  defp get_config(backend) do
    case Application.get_env(:pubsubber, :backends, [])[backend] do
      nil -> %{}
      other -> other
    end
  end

  defp new_ets_or_reuse(ets_table, args) do
    case :ets.whereis(ets_table) do
      :undefined -> :ets.new(ets_table, args)
      _ -> ets_table
    end
  end

  @doc """
  Returns the current set backend with the process id
  """
  @spec publisher_conn() :: {module, pid}
  def publisher_conn do
    :ets.lookup_element(@ets_table, :publisher, 2)
  end

  @spec subscriber_conn() :: {module, pid}
  def subscriber_conn do
    :ets.lookup_element(@ets_table, :subscriber, 2)
  end

  def subscribe(conn \\ subscriber_conn(), send_to_pid, topic) do
    case conn do
      {backend, conn} -> backend.subscribe(conn, send_to_pid, topic)
      other -> raise "Invalid connection #{inspect(other)}"
    end
  end

  def unsubscribe(conn \\ subscriber_conn(), send_to_pid, topic_or_id) do
    case conn do
      {backend, conn} -> backend.unsubscribe(conn, send_to_pid, topic_or_id)
      other -> raise "Invalid connection #{inspect(other)}"
    end
  end

  def publish(conn \\ publisher_conn(), topic, message) do
    case conn do
      {backend, conn} -> backend.publish(conn, topic, message)
      other -> raise "Invalid connection #{inspect(other)}"
    end
  end
end
