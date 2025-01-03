defmodule Elixpeer.Trackers do
  @moduledoc """
  Functions to deal with Trackers in the database.
  """
  alias Elixpeer.Repo
  alias Elixpeer.Tracker

  @spec list :: [Tracker.t()]
  def list do
    Repo.all(Tracker)
  end

  @doc """
  Inserts the torrent into the database.
  """
  @spec insert(map()) :: Tracker.t()
  def insert(attrs) do
    %Tracker{}
    |> Tracker.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Inserts the torrent into the database, updating if necessary.
  """
  @spec upsert(map()) :: Tracker.t()
  def upsert(attrs) do
    %Tracker{}
    |> Tracker.changeset(attrs)
    |> Repo.insert!(
      on_conflict: {:replace_all_except, [:id, :inserted_at, :updated_at]},
      conflict_target: [:announce, :scrape, :sitename, :tier],
      returning: true
    )
  end
end
