defmodule BlockchainAPI.Explorer do
  @moduledoc """
  The Explorer context.
  """

  import Ecto.Query, warn: false
  alias BlockchainAPI.Repo

  alias BlockchainAPI.Explorer.Block

  @doc """
  Returns the list of blocks.

  ## Examples

      iex> list_blocks()
      [%Block{}, ...]

  """
  def list_blocks do
    Repo.all(Block)
  end

  @doc """
  Gets a single block.

  Raises `Ecto.NoResultsError` if the Block does not exist.

  ## Examples

      iex> get_block!(123)
      %Block{}

      iex> get_block!(456)
      ** (Ecto.NoResultsError)

  """
  def get_block!(height), do: Repo.get!(Block, height)

  @doc """
  Creates a block.

  ## Examples

      iex> create_block(%{field: value})
      {:ok, %Block{}}

      iex> create_block(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_block(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest() do
    query = from block in Block, select: max(block.height)
    Repo.all(query)
  end


  alias BlockchainAPI.Explorer.Coinbase

  @doc """
  Returns the list of coinbase_transactions.

  ## Examples

      iex> list_coinbase_transactions()
      [%Coinbase{}, ...]

  """
  def list_coinbase_transactions do
    Repo.all(Coinbase)
  end

  @doc """
  Gets a single coinbase.

  Raises `Ecto.NoResultsError` if the Coinbase does not exist.

  ## Examples

      iex> get_coinbase!(123)
      %Coinbase{}

      iex> get_coinbase!(456)
      ** (Ecto.NoResultsError)

  """
  def get_coinbase!(id), do: Repo.get!(Coinbase, id)

  @doc """
  Creates a coinbase.

  ## Examples

      iex> create_coinbase(%{field: value})
      {:ok, %Coinbase{}}

      iex> create_coinbase(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_coinbase(attrs \\ %{}) do
    %Coinbase{}
    |> Coinbase.changeset(attrs)
    |> Repo.insert()
  end

  alias BlockchainAPI.Explorer.Payment

  @doc """
  Returns the list of payment_transactions.

  ## Examples

      iex> list_payment_transactions()
      [%Payment{}, ...]

  """
  def list_payment_transactions do
    Repo.all(Payment)
  end

  @doc """
  Gets a single payment.

  Raises `Ecto.NoResultsError` if the Payment does not exist.

  ## Examples

      iex> get_payment!(123)
      %Payment{}

      iex> get_payment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_payment!(id), do: Repo.get!(Payment, id)

  @doc """
  Creates a payment.

  ## Examples

      iex> create_payment(%{field: value})
      {:ok, %Payment{}}

      iex> create_payment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment(attrs \\ %{}) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  alias BlockchainAPI.Explorer.Gateway

  @doc """
  Returns the list of add_gateway_transactions.

  ## Examples

      iex> list_add_gateway_transactions()
      [%Gateway{}, ...]

  """
  def list_add_gateway_transactions do
    Repo.all(Gateway)
  end

  @doc """
  Gets a single gateway.

  Raises `Ecto.NoResultsError` if the Gateway does not exist.

  ## Examples

      iex> get_gateway!(123)
      %Gateway{}

      iex> get_gateway!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gateway!(id), do: Repo.get!(Gateway, id)

  @doc """
  Creates a gateway.

  ## Examples

      iex> create_gateway(%{field: value})
      {:ok, %Gateway{}}

      iex> create_gateway(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gateway(attrs \\ %{}) do
    %Gateway{}
    |> Gateway.changeset(attrs)
    |> Repo.insert()
  end


  alias BlockchainAPI.Explorer.GatewayLocation

  @doc """
  Returns the list of assert_location_transactions.

  ## Examples

      iex> list_assert_location_transactions()
      [%GatewayLocation{}, ...]

  """
  def list_assert_location_transactions do
    Repo.all(GatewayLocation)
  end

  @doc """
  Gets a single gateway_location.

  Raises `Ecto.NoResultsError` if the Gateway location does not exist.

  ## Examples

      iex> get_gateway_location!(123)
      %GatewayLocation{}

      iex> get_gateway_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gateway_location!(id), do: Repo.get!(GatewayLocation, id)

  @doc """
  Creates a gateway_location.

  ## Examples

      iex> create_gateway_location(%{field: value})
      {:ok, %GatewayLocation{}}

      iex> create_gateway_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gateway_location(attrs \\ %{}) do
    %GatewayLocation{}
    |> GatewayLocation.changeset(attrs)
    |> Repo.insert()
  end
end
