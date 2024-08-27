defmodule Elixpeer.Repo.Migrations.UpdatePolicyDaily do
  use Ecto.Migration

  def change do
    execute """
    SELECT add_continuous_aggregate_policy('activity_per_day_per_torrent',
                                          start_offset => INTERVAL '1 month',
                                          end_offset => INTERVAL 'NULL',
                                          schedule_interval => INTERVAL '1 hour');
    """
  end
end
