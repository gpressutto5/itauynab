defmodule Itauynab.Ynab do
  use Hound.Helpers
  alias Itauynab.Download

  def open_and_login do
    navigate_to("https://app.ynab.com/users/sign_in")

    fill_field({:id, "request_data_email"}, System.get_env("YNAB_EMAIL"))
    Process.sleep(100)
    fill_field({:id, "request_data_password"}, System.get_env("YNAB_PASSWORD"))
    Process.sleep(100)
    find_element(:id, "login") |> click()

    find_element(:class, "user-logged-in", 50)
  end

  def upload_ofx_file do
    navigate_to(
      "https://app.ynab.com/#{System.get_env("YNAB_BUDGET_ID")}/accounts/#{System.get_env("YNAB_CHECKING_ACCOUNT_ID")}"
    )

    find_element(:class, "accounts-toolbar-file-import-transactions", 100) |> click()

    file = Download.list_files("*.ofx") |> Enum.at(0)
    session_id = Hound.current_session_id()
    element = find_element(:css, ".file-picker > input[type=file]")

    Hound.RequestUtils.make_req(:post, "session/#{session_id}/element/#{element}/value", %{
      value: ["#{file}"]
    })

    include_earlier_transactions_el = find_element(:css, ".import-preview-warning > .ynab-checkbox")
    unless include_earlier_transactions_el |> has_class?("is-checked") do
      include_earlier_transactions_el |> click()
    end

    swap_memo_with_payee_el = find_element(:class, "swap-memo-with-payee")
    unless swap_memo_with_payee_el |> has_class?("is-checked") do
      swap_memo_with_payee_el |> click()
    end

    import_memos_el = find_element(:class, "import-memos")
    unless import_memos_el |> has_class?("is-checked") do
      import_memos_el |> click()
    end

    Process.sleep(500)

    find_element(
      :css,
      ".modal-import-review > .modal > .modal-fresh-footer > .ynab-button.primary"
    )
    |> click()

    Process.sleep(500)

    find_element(
      :css,
      ".modal-import-successful > .modal > .modal-fresh-footer > .ynab-button.primary",
      20
    )
    |> click()

    Process.sleep(1000)

    File.rm!(file)
  end
end
