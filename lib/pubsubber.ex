defmodule Pubsubber do
  @moduledoc """
  Documentation for `Pubsubber`.
  """

  @doc """
  Create a subscription stream which waits until `timeout` for each message

  ```elixir
  iex> "testing" |> Pubsubber.stream(1) |> Enum.to_list()
  # no messages in this small timeframe
  []
  iex> "testing" |> Pubsubber.stream(1) |> Stream.run()
  # no messages in this small timeframe
  :ok
  ```
  """
  def stream(topic, timeout \\ :infinity) do
    Pubsubber.Stream.subscribe(topic, timeout)
  end

  @doc """
  Convience function that calls the callback function with the message received

  ```elixir
  iex> Pubsubber.listen("testing", &IO.inspect/1, 1)
  :ok
  ```
  """
  def listen(topic, callback, timeout \\ :infinity) do
    topic
    |> stream(timeout)
    |> Stream.each(callback)
    |> Stream.run()
  end

  @doc """
  Subscribe to topic and send message to pid
  """
  def subscribe(send_to_pid, topic) do
    Pubsubber.Backend.subscribe(send_to_pid, topic)
  end

  @doc """
  Unsubscribe from topic with pid
  """
  def unsubscribe(send_to_pid, topic_or_id) do
    Pubsubber.Backend.unsubscribe(send_to_pid, topic_or_id)
  end

  @doc """
  Publish message to topic
  """
  def publish(topic, message) do
    Pubsubber.Backend.publish(topic, message)
  end
end
