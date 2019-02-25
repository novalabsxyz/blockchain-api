defmodule BlockchainAPI.Util do
  def bin_to_string(nil), do: nil
  def bin_to_string(bin) do
    bin
    |> :libp2p_crypto.bin_to_b58()
    |> to_string
  end

  def string_to_bin(nil), do: nil
  def string_to_bin(string) do
    string
    |> to_charlist()
    |> :libp2p_crypto.b58_to_bin()
  end

  def h3_to_lat_lng(nil), do: {nil, nil}
  def h3_to_lat_lng(loc) do
    loc
    |> String.to_charlist()
    |> :h3.from_string()
    |> :h3.to_geo()
  end
end
