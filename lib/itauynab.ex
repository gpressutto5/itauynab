defmodule Itauynab do
  @moduledoc """
  Documentation for `Itauynab`.
  """

  use Hound.Helpers
  alias Itauynab.{Download, Itau, Ynab}

  def run do
    Envy.auto_load()
    Application.ensure_all_started(:hound)
    start_browser()
    Download.set_download_path()

    try do
      Itau.open_and_login()
      Itau.download_ofx_file()
      # Itau.download_xls_files()
      # convert_xls_to_csv()
      Ynab.open_and_login()
      Ynab.upload_ofx_file()
      # upload_csv_files()
    after
      stop_browser()
    end
  end

  defp start_browser do
    Hound.start_session(additional_capabilities: %{browserName: "chrome"})
  end

  defp stop_browser do
    Hound.end_session()
  end
end
