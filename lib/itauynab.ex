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
      checking_balance = Itau.download_ofx_file()
      credit_card_balance = Itau.download_csv_file()
      Ynab.open_and_login()
      Ynab.upload_ofx_file(checking_balance)
      Ynab.upload_csv_file(credit_card_balance)

      IO.puts("Checking balance: #{checking_balance/100}")
      IO.puts("Credit card balance: #{credit_card_balance/100}")
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
