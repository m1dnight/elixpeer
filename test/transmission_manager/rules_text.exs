defmodule TransmissionManager.RulesTest do
  use TransmissionManagerWeb.DataCase, async: true

  import TransmissionManager.Rules


  describe "rule tests" do
    # rule
    rule = older_than(10)

    # torrent
    torrent = %TransmissionManager.Torrent{
      id: 1,
      name: "torrent1",
      date_added: DateTime.utc_now() |> DateTime.add(-11)
    }

    assert match_rule?(rule, torrent) == false
  end
end
