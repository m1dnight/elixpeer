defmodule TransmissionManager.Notifier do
  @moduledoc """
  Sends notifications to the user about changes to the torrents.
  """
  use Phoenix.Swoosh,
    template_root: "lib/transmission_manager/notifier/",
    template_path: "/"

  alias TransmissionManager.Mailer
  alias TransmissionManager.Torrent

  @spec send_notification(:torrent_deleted, [Torrent.t()]) :: {:error, term()} | {:ok, term()}
  def send_notification(:torrent_deleted, torrents) do
    from_address = Application.get_env(:transmission_manager, :mail_from_address)
    to_address = Application.get_env(:transmission_manager, :mail_to_address)
    to_name = Application.get_env(:transmission_manager, :mail_to_name)

    new()
    |> to({to_name, to_address})
    |> from({"Transmission Manager", from_address})
    |> subject("Removed #{Enum.count(torrents)} torrents")
    |> render_body("torrent_deleted.html", %{torrents: torrents})
    |> text_body("foo")
    |> put_provider_option(:message_stream, "broadcast")
    |> Mailer.deliver()
  end
end
