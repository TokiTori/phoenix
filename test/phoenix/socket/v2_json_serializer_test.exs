defmodule Phoenix.Socket.V2.JSONSerializerTest do
  use ExUnit.Case, async: true
  alias Phoenix.Socket.{Broadcast, Message, Reply, V2}

  @serializer V2.JSONSerializer
  @v2_fastlane_json "[null,null,\"t\",\"e\",\"m\"]"
  @v2_reply_json "[null,null,\"t\",\"phx_reply\",{\"response\":\"m\",\"status\":null}]"
  @v2_msg_json "[null,null,\"t\",\"e\",\"m\"]"

  @push <<
    0::size(8), # push
    2, # join_ref_size
    3, # ref_size
    5, # topic_size
    5, # event_size
    "12",
    "123",
    "topic",
    "event",
    101,
    102,
    103
  >>

  @reply <<
    1::size(8), # reply
    2, # join_ref_size
    3, # ref_size
    5, # topic_size
    2, # status_size
    "12",
    "123",
    "topic",
    "ok",
    101,
    102,
    103
  >>

  @broadcast <<
    2::size(8), # broadcast
    5, # topic_size
    5, # event_size
    "topic",
    "event",
    101,
    102,
    103
  >>

  def encode!(serializer, msg) do
    case serializer.encode!(msg) do
      {:socket_push, :text, encoded} ->
        assert is_list(encoded)
        IO.iodata_to_binary(encoded)

      {:socket_push, :binary, encoded} ->
        assert is_binary(encoded)
        encoded
    end
  end

  def decode!(serializer, msg, opts \\ []) do
    serializer.decode!(msg, opts)
  end

  def fastlane!(serializer, msg) do
    case serializer.fastlane!(msg) do
      {:socket_push, :text, encoded} ->
        assert is_list(encoded)
        IO.iodata_to_binary(encoded)

      {:socket_push, :binary, encoded} ->
        assert is_binary(encoded)
        encoded
    end
  end

  test "encode!/1 encodes `Phoenix.Socket.Message` as JSON" do
    msg = %Message{topic: "t", event: "e", payload: "m"}
    assert encode!(@serializer, msg) == @v2_msg_json
  end

  test "encode!/1 encodes `Phoenix.Socket.Reply` as JSON" do
    msg = %Reply{topic: "t", payload: "m"}
    assert encode!(@serializer, msg) == @v2_reply_json
  end

  test "decode!/2 decodes `Phoenix.Socket.Message` from JSON" do
    assert %Message{topic: "t", event: "e", payload: "m"} ==
      decode!(@serializer, @v2_msg_json, opcode: :text)
  end

  test "fastlane!/1 encodes a broadcast into a message as JSON" do
    msg = %Broadcast{topic: "t", event: "e", payload: "m"}
    assert fastlane!(@serializer, msg) == @v2_fastlane_json
  end

  describe "binary encode" do
    test "general pushed message" do
      assert encode!(@serializer, %Phoenix.Socket.Message{
              join_ref: "12",
              ref: "123",
              topic: "topic",
              event: "event",
              payload: {:binary, <<101, 102, 103>>}
            }) == @push
    end

    test "reply" do
      assert encode!(@serializer, %Phoenix.Socket.Reply{
              join_ref: "12",
              ref: "123",
              topic: "topic",
              status: :ok,
              payload: {:binary, <<101, 102, 103>>}
            }) == @reply
    end

    test "fastlane" do
      assert fastlane!(@serializer, %Phoenix.Socket.Broadcast{
              topic: "topic",
              event: "event",
              payload: {:binary, <<101, 102, 103>>}
            }) == @broadcast
    end
  end

  describe "binary decode" do
    test "pushed message" do
      assert decode!(@serializer, @push, opcode: :binary) == %Phoenix.Socket.Message{
              join_ref: "12",
              ref: "123",
              topic: "topic",
              event: "event",
              payload: {:binary, <<101, 102, 103>>}
            }
    end
  end
end
