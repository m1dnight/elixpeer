defmodule Elixpeer.Repo.Migrations.CreateTorrents do
  use Ecto.Migration

  def change do
    create table(:torrents) do
      add :name, :string
      add :size, :bigint
      add :added_date, :naive_datetime
      add :is_finished, :boolean, default: false, null: false
      add :rate_download, :integer
      add :rate_upload, :integer
      add :size_when_done, :bigint
      add :upload_ratio, :float
      add :percent_done, :float
      add :uploaded, :bigint
      add :downloaded, :bigint

      add :status, :text

      add :activity_date, :naive_datetime
      add :transmission_id, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:torrents, [:transmission_id, :name])
  end
end
