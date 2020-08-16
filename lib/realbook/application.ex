defmodule Realbook.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_, _) do
    children = [
      Realbook.Storage,
      {Realbook.Semaphore, Compiler},
      {Registry, keys: :unique, name: Realbook.Semaphore.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: Realbook.Semaphore.Supervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
