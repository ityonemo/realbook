defmodule Realbook.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_, _) do
    children = [
      Realbook.Storage,
      {Realbook.Semaphore, Compiler}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
