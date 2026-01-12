defmodule UniverseWeb.PageController do
  use UniverseWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
