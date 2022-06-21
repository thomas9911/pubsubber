defmodule Pubsubber.Backend.GenServer do
  use GenServer

  @behaviour Pubsubber.Backend

  defguard is_event(event, _, topic)
           when elem(event, 0) == :pubsubber_genserver and elem(event, 1) == topic

  def start_link(_, _) do
    case GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      e -> raise inspect(e)
    end
  end

  @impl true
  def init(_) do
    {:ok, %{subscribers: %{}}}
  end

  @impl Pubsubber.Backend
  def subscribe(conn, send_to_pid, topic) do
    GenServer.cast(conn, {:subscribe, {send_to_pid, topic}})
    {:ok, []}
  end

  @impl Pubsubber.Backend
  def unsubscribe(conn, send_to_pid, topic) do
    GenServer.cast(conn, {:unsubscribe, {send_to_pid, topic}})
  end

  @impl Pubsubber.Backend
  def publish(conn, topic, message) when is_binary(topic) do
    case String.Chars.impl_for(message) do
      nil -> {:error, :invalid_message}
      _ -> GenServer.cast(conn, {:publish, {topic, to_string(message)}})
    end
  end

  @impl Pubsubber.Backend
  def extract_message({:pubsubber_genserver, _, message}), do: message

  def state(conn) do
    :sys.get_state(conn)
  end

  @impl true
  def handle_cast({:subscribe, {send_to_pid, topic}}, %{subscribers: subscribers} = state) do
    subscribers = Map.update(subscribers, topic, [send_to_pid], fn acc -> [send_to_pid | acc] end)
    {:noreply, %{state | subscribers: subscribers}}
  end

  def handle_cast({:unsubscribe, {send_to_pid, topic}}, %{subscribers: subscribers} = state) do
    {_, subscribers} = Map.get_and_update(subscribers, topic, &unsubscriber(&1, send_to_pid))
    {:noreply, %{state | subscribers: subscribers}}
  end

  def handle_cast({:publish, {topic, message}}, %{subscribers: subscribers} = state) do
    subscribers
    |> Map.get(topic, [])
    |> Enum.each(&send(&1, {:pubsubber_genserver, topic, message}))

    {:noreply, state}
  end

  def unsubscriber(nil, _), do: :pop

  def unsubscriber(acc, send_to_pid) do
    case Enum.reject(acc, &(&1 == send_to_pid)) do
      [] -> :pop
      pids -> {nil, pids}
    end
  end
end
