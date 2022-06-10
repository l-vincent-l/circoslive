defmodule Circos.Worker do
  use Agent

  def start_link(_) do
    Agent.start_link(&download/0, name: __MODULE__)
  end

  def find(lon, lat) do
    Agent.get(__MODULE__, & &1)
    |> Enum.reject(fn {b, _} -> !within({lon, lat}, b) end)
    |> Enum.find_value(fn {_, i} -> within_circo({lon, lat}, i)  end)
    |> get_departement_ref()
  end
  def find([lon, lat]) do
    find(lon, lat)
  end

  defp get_departement_ref(%{properties: %{"REF" => "0" <> <<departement::bytes-size(2)>>  <> "-" <> reference}}) do
    %{departement: departement, reference: reference}
  end
  defp get_departement_ref(%{properties: %{"REF" => <<departement::bytes-size(3)>> <> "-" <> reference}}) do
    %{departement: departement, reference: reference}
  end

  def get_all do
    Agent.get(__MODULE__, & &1)
  end

  defp download do
    {:ok, temp_path} = Temp.path(suffix: ".zip")
    :inets.start()

    url = "http://panneaux-election.fr/carte/circonscriptions-legislatives.json.zip"
    :httpc.request(:get, {url, []}, [], [stream: String.to_charlist(temp_path)])
    {:ok, [{_, body}] } = :zip.unzip(String.to_charlist(temp_path), [:memory])

    {:ok, circos } = body |> Jason.decode! |> Geo.JSON.decode

    :ets.new(:circos, [:named_table])
    circos.geometries
    |> Enum.with_index()
    |> Enum.map(fn {c, i} -> :ets.insert(:circos, {i, c}) end)

    circos.geometries |> Enum.map(&Circos.Worker.bounding_box/1) |> Enum.with_index()
  end

  def bounding_box(%{coordinates: coordinates}) do
    {{min_x, _}, {max_x, _}} = coordinates |> List.flatten |> Enum.min_max_by(fn {x, _} -> x end)
    {{_, min_y}, { _, max_y}} = coordinates |> List.flatten |> Enum.min_max_by(fn {_, y} -> y end)
    [{min_x, min_y}, {max_x, max_y}]
  end

  def within({lon, lat}, [{min_lon, min_lat}, {max_lon, max_lat}]) do
    lon>=min_lon && lon <=max_lon && lat>=min_lat && lat <= max_lat
  end

  def within_circo(coordinates, i) do
    with [{_, circo}] <- :ets.lookup(:circos, i),
         true <- Topo.contains?(circo, %Geo.Point{coordinates: coordinates}) do
      circo
    else
      _ -> false
    end
  end
end
