defmodule Pubsubber.Stream do
  require Logger
  require Pubsubber.Backend.Redis
  require Pubsubber.Backend.Nats
  require Pubsubber.Backend.GenServer

  @spec subscribe(binary, timeout) :: Enumerable.t()
  def subscribe(topic, timeout \\ :infinity) do
    Stream.resource(
      fn -> init(topic) end,
      &main_loop(&1, topic, timeout),
      fn result -> final(result, topic) end
    )
  end

  defp init(topic) do
    {backend, _} = conn = Pubsubber.Backend.subscriber_conn()

    case Pubsubber.Backend.subscribe(conn, self(), topic) do
      {:ok, ref} -> {ref, backend}
      err -> err
    end
  end

  defp final({:timeout, {sid, Pubsubber.Backend.Nats}, timeout}, _) do
    Logger.info("No message in #{timeout} seconds")
    final(sid)
  end

  defp final({:timeout, _, timeout}, topic) do
    Logger.info("No message in #{timeout} seconds")
    final(topic)
  end

  defp final(error, topic) do
    Logger.error("Pubsubber.Stream subscribe errored with #{inspect(error)}")
    final(topic)
  end

  defp final(topic) do
    Pubsubber.Backend.unsubscribe(self(), topic)
  end

  defp main_loop({:error, error}, _, _) do
    {:halt, {:error, error}}
  end

  defp main_loop({ref, backend} = conn, topic, timeout) do
    receive do
      event
      when backend == Pubsubber.Backend.Redis and
             Pubsubber.Backend.Redis.is_event(event, ref, topic) ->
        {[Pubsubber.Backend.Redis.extract_message(event)], conn}

      event
      when backend == Pubsubber.Backend.Nats and
             Pubsubber.Backend.Nats.is_event(event, ref, topic) ->
        {[Pubsubber.Backend.Nats.extract_message(event)], conn}

      event
      when backend == Pubsubber.Backend.GenServer and
             Pubsubber.Backend.GenServer.is_event(event, ref, topic) ->
        {[Pubsubber.Backend.GenServer.extract_message(event)], conn}

      _ ->
        {[], conn}
    after
      timeout ->
        {:halt, {:timeout, conn, timeout}}
    end
  end
end
