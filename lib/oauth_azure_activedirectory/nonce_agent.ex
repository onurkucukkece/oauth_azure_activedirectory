defmodule OauthAzureActivedirectory.NonceAgent do
  use Agent

  def start_link() do
    Agent.start_link(fn -> MapSet.new end, name: __MODULE__)
  end

  def put(nonce) do
    Agent.update(__MODULE__, &MapSet.put(&1, nonce))
  end

  def check_and_delete(nonce) do
    is_member = Agent.get(__MODULE__, &MapSet.member?(&1, nonce))
    Agent.update(__MODULE__, &MapSet.delete(&1, nonce))
    is_member
  end
end
