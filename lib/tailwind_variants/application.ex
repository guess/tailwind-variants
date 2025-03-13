defmodule TailwindVariants.Application do
  use Application

  def start(_type, _args) do
    children = [
      TwMerge.Cache
    ]

    opts = [strategy: :one_for_one, name: TailwindVariants.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
