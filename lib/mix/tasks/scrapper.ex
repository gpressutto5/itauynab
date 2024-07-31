defmodule Mix.Tasks.Scrapper do
  use Mix.Task
  use Hound.Helpers

  alias Itauynab.{Download, Itau, Ynab}

  def run(_) do
    setup()

    Itau.login()
    Itau.download_ofx_file()

    Ynab.login()
    Ynab.upload_ofx_file()
  after
    Hound.end_session()
  end

  defp setup do
    Envy.auto_load()
    Application.ensure_all_started(:hound)

    Hound.start_session(additional_capabilities: %{browserName: "chrome"})

    Download.set_download_path()
  end
end
