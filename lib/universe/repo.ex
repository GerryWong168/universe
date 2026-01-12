defmodule Universe.Repo do
  use Ecto.Repo,
    otp_app: :universe,
    adapter: Ecto.Adapters.Postgres
end
