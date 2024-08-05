defmodule Elixpeer.Repo.Migrations.RemoveTransmissionId do
  use Ecto.Migration

  def change do
    alter table(:torrents) do
      remove :transmission_id
    end

    # remove duplicates, if there are any
    execute """
    WITH cte AS (SELECT id,
                        name,
                        ROW_NUMBER() OVER (PARTITION BY name ORDER BY id desc) AS rn
                FROM torrents)
    delete
    from torrents
    where id in (select id from cte where rn > 1);
    """

    # put the index on the name alone
    create unique_index(:torrents, [:name])
  end
end
