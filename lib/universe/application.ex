defmodule Universe.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UniverseWeb.Telemetry,
      Universe.Repo,
      {DNSCluster, query: Application.get_env(:universe, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Universe.PubSub},
      # Start a worker by calling: Universe.Worker.start_link(arg)
      # {Universe.Worker, arg},
      # Start to serve requests, typically the last entry
      UniverseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Universe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    UniverseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
