defmodule Pubsubber.Backend.Redis do
  @behaviour Pubsubber.Backend

  # {:redix_pubsub, _, ^ref, :message, %{channel: ^topic}}
  defguard is_event(event, ref, topic)
           when elem(event, 0) == :redix_pubsub and
                  elem(event, 2) == ref and
                  elem(event, 3) == :message and
                  elem(event, 4).channel == topic

  def start_link(:publisher, config) do
    url =
      case Access.fetch(config, :url) do
        {:ok, url} -> url
        _ -> raise "Redis url is not set"
      end

    Redix.start_link(url)
  end

  def start_link(:subscriber, config) do
    url =
      case Access.fetch(config, :url) do
        {:ok, url} -> url
        _ -> raise "Redis url is not set"
      end

    Redix.PubSub.start_link(url)
  end

  def subscribe(conn, send_to_pid, topic) do
    Redix.PubSub.subscribe(conn, topic, send_to_pid)
  end

  def unsubscribe(conn, send_to_pid, topic) do
    Redix.PubSub.unsubscribe(conn, topic, send_to_pid)
  end

  def publish(conn, topic, message) when is_binary(topic) do
    case String.Chars.impl_for(message) do
      nil -> {:error, :invalid_message}
      _ -> Redix.noreply_command(conn, ["PUBLISH", topic, message])
    end
  end

  def extract_message({:redix_pubsub, _, _, :message, %{payload: payload}}), do: payload
end
