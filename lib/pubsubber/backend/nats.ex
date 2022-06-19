defmodule Pubsubber.Backend.Nats do
  @behaviour Pubsubber.Backend

  # {:msg, %{  body: "hey there",  gnat: #PID<0.250.0>,  reply_to: nil,  sid: 1,  topic: "hallo" }}
  defguard is_event(event, ref, topic)
           when elem(event, 0) == :msg and elem(event, 1).sid == ref and
                  elem(event, 1).topic == topic

  def start_link(_, config) do
    Gnat.start_link(config)
  end

  def subscribe(conn, send_to_pid, topic) do
    Gnat.sub(conn, send_to_pid, topic)
  end

  def unsubscribe(conn, _send_to_pid, topic) do
    Gnat.unsub(conn, topic)
  end

  def publish(conn, topic, message) when is_binary(topic) do
    case String.Chars.impl_for(message) do
      nil -> {:error, :invalid_message}
      _ -> Gnat.pub(conn, topic, to_string(message))
    end
  end

  def extract_message({:msg, %{body: body}}), do: body
end
