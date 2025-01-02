defmodule Elixpeer.Torrent do
  @moduledoc """
  Defines a struct to hold torrent information.
  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias Elixpeer.Torrent
  alias Elixpeer.TorrentActivity
  alias Elixpeer.Trackers

  typed_schema "torrents" do
    field :activity_date, :naive_datetime
    field :added_date, :naive_datetime
    field :downloaded, :integer
    field :is_finished, :boolean, default: false
    field :name, :string
    field :percent_done, :float
    field :rate_download, :integer
    field :rate_upload, :integer
    field :size_when_done, :integer
    field :transmission_id, :integer

    field :status, Ecto.Enum,
      values: [
        :stopped,
        :queued_to_verify,
        :verifying,
        :queued_to_download,
        :downloading,
        :queued_to_seed,
        :seeding,
        :deleted
      ]

    field :upload_ratio, :float
    field :uploaded, :integer

    many_to_many :trackers, Elixpeer.Tracker,
      join_through: "torrents_trackers",
      on_replace: :delete

    has_many :torrent_activities, TorrentActivity

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(Torrent.t(), map()) :: Ecto.Changeset.t()
  def changeset(torrent, params) do
    torrent
    |> cast(params, [
      :activity_date,
      :added_date,
      :downloaded,
      :is_finished,
      :name,
      :percent_done,
      :rate_download,
      :rate_upload,
      :size_when_done,
      :status,
      :upload_ratio,
      :uploaded,
      :transmission_id
    ])
    |> validate_required([
      :activity_date,
      :added_date,
      :downloaded,
      :is_finished,
      :name,
      :percent_done,
      :rate_download,
      :rate_upload,
      :size_when_done,
      :status,
      :upload_ratio,
      :uploaded,
      :transmission_id
    ])
    |> Ecto.Changeset.put_assoc(:trackers, parse_trackers(params))
  end

  defp parse_trackers(params) do
    params
    |> Map.get(:trackers, [])
    |> Enum.map(&Trackers.upsert/1)
  end
end
