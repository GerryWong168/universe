defmodule UniverseWeb.PageController do
  use UniverseWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def tools(conn, _params) do
    render(conn, :tools)
  end
end
