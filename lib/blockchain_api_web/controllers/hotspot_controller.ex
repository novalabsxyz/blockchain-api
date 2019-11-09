defmodule BlockchainAPIWeb.HotspotController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Query, Util}
  alias BlockchainAPIWeb.{POCReceiptsView, POCWitnessesView}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    hotspots = Query.Hotspot.list(params)

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render(
      "index.json",
      hotspots: hotspots
    )
  end

  def show(conn, %{"address" => address}) do
    hotspot =
      address
      |> Util.string_to_bin()
      |> Query.Hotspot.get!()

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render("show.json", hotspot: hotspot)
  end

  def search(conn, %{"term" => term} = _params) do
    results = Query.Hotspot.search(term)

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render(
      "search.json",
      results: results
    )
  end

  def timeline(conn, _params) do
    hotspots = Query.Hotspot.all_by_time()

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> render(
      "timeline.json",
      hotspots: hotspots
    )
  end

  def receipts(conn, %{"hotspot_address" => address}) do
    receipts =
      with address <- Util.string_to_bin(address),
           hotspot when not is_nil(hotspot) <- Query.Hotspot.get!(address) do
        Query.POCReceipt.list_for(hotspot.address)
      else
        _ -> nil
      end

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> put_view(POCReceiptsView)
    |> render("index.json", poc_receipts: receipts)
  end

  def witnesses(conn, %{"hotspot_address" => address}) do
    witnesses =
      with address <- Util.string_to_bin(address),
           hotspot when not is_nil(hotspot) <- Query.Hotspot.get!(address) do
        Query.POCWitness.list_for(hotspot.address)
      else
        _ -> nil
      end

    conn
    |> put_resp_header("surrogate-key", "block")
    |> put_resp_header("surrogate-control", "max-age=300")
    |> put_resp_header("cache-control", "max-age=300")
    |> put_view(POCWitnessesView)
    |> render("index.json", poc_witnesses: witnesses)
  end
end
