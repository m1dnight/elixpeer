defmodule Elixpeer.Elixpeer.TorrentTracker do
  @moduledoc """
  Defines the join struct for trackers and torrents.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  alias __MODULE__

  typed_schema "torrents_trackers" do
    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(TorrentTracker.t(), map()) :: Ecto.Changeset.t()
  def changeset(torrent_tracker, attrs) do
    torrent_tracker
    |> cast(attrs, [])
    |> validate_required([])
  end
end
