defmodule TransmissionManagerWeb.PageControllerTest do
  use TransmissionManagerWeb.ConnCase

  test "GET /index", %{conn: conn} do
    conn = get(conn, ~p"/index")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
