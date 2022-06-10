defmodule CircosWeb.PageController do
  use CircosWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
