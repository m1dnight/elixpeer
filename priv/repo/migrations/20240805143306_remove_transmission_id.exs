defmodule Elixpeer.Repo.Migrations.RemoveTransmissionId do
  use Ecto.Migration

  def change do
    alter table(:torrents) do
      remove :transmission_id
    end

    # migrate the torrent foreign key in the activities
    execute """
    create temporary table new_ids as
    select t1.name, t1.id as original_id, max(t2.id) as new_id
    from torrents t1
            join torrents t2 on t1.name = t2.name
    where t1.id < t2.id
    group by t1.name, t1.id;
    """

    execute """
    delete from torrents where id in (select original_id from new_ids);
    """

    # put the index on the name alone
    create unique_index(:torrents, [:name])
  end
end
