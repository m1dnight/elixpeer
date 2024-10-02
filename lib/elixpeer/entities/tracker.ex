defmodule Elixpeer.Tracker do
  @moduledoc """
  Defines a Tracker struct.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  alias Elixpeer.Tracker

  typed_schema "trackers" do
    field :announce, :string
    field :scrape, :string
    field :tier, :integer
    field :sitename, :string

    many_to_many :torrents, Elixpeer.Torrent,
      join_through: "torrents_trackers",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(Tracker.t(), map()) :: Ecto.Changeset.t()
  def changeset(tracker, attrs) do
    tracker
    |> cast(attrs, [:announce, :scrape, :tier, :sitename])
    |> validate_required([:announce, :tier, :sitename])
  end
end
