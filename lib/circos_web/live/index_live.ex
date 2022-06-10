defmodule CircoWeb.IndexLive do
  use Phoenix.LiveView, layout: {CircosWeb.LayoutView, "live.html"}

  def render(%{results: false} = assigns) do
    ~H"""
      <label for="autoComplete">Recherchez une adresse</label>
      <input type="text" placeholder="une adresse" id="autoComplete" phx-hook="Autocomplete">
    """
  end

  def render(assigns) do
    ~H"""
      <p class="row">Adresse : <%= @label %></p>
      <p class="row">Circonscription : <%= @circo.reference %> du département <%= @circo.departement %></p>
      <p class="row"><button phx-click="reset">Cherche une nouvelle adresse</button></p>
    """
  end

  def mount(_params, _assigns, socket) do
    {:ok, assign(socket, results: false)}
  end


  def handle_event("selection", %{"label" => label, "coords" => coords}, socket) do
    circo = Circos.Worker.find(coords)
    {:noreply, assign(socket, results: true, label: label, circo: circo)}
  end

  def handle_event("reset", _key, socket) do
    {:noreply, assign(socket, results: false)}
  end
end
