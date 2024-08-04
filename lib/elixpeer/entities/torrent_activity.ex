defmodule Elixpeer.TorrentActivity do
  @moduledoc """
  Defines a struct to hold activity for a torrent to track its progress.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  alias Elixpeer.Torrent
  alias Elixpeer.TorrentActivity

  @primary_key false
  typed_schema "torrent_activities" do
    field :upload, :integer
    field :uploaded, :integer
    field :downloaded, :integer
    field :download, :integer
    belongs_to :torrent, Torrent

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(TorrentActivity.t(), map()) :: Ecto.Changeset.t()
  def changeset(torrent_activity, attrs) do
    torrent_activity
    |> cast(attrs, [:uploaded, :downloaded, :upload, :download, :torrent_id])
    |> validate_required([:uploaded, :downloaded, :upload, :download, :torrent_id])
  end
end
