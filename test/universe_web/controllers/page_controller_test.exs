defmodule UniverseWeb.PageControllerTest do
  use UniverseWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Classic Star Trek Space Game"
  end

  test "GET /tools", %{conn: conn} do
    conn = get(conn, ~p"/tools")
    html = html_response(conn, 200)

    assert html =~ "Calculator Pages"
    assert html =~ "Tepic House Calculator"
    assert html =~ "Low Cost Housing Construction in Mexico"
  end
end
