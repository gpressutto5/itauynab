defmodule Itauynab.Ynab do
  use Hound.Helpers

  alias Itauynab.Download

  @base_url "https://app.ynab.com"

  def login do
    navigate_to("#{@base_url}/users/sign_in")

    Process.sleep(1000)
    fill_field({:id, "request_data_email"}, System.fetch_env!("YNAB_EMAIL"))
    Process.sleep(1000)
    fill_field({:id, "request_data_password"}, System.fetch_env!("YNAB_PASSWORD"))
    Process.sleep(1000)
    find_element(:id, "login") |> click()

    find_element(:class, "user-logged-in", 50)
  end

  def upload_ofx_file do
    navigate_to(
      "https://app.ynab.com/#{System.fetch_env!("YNAB_BUDGET_ID")}/accounts/#{System.fetch_env!("YNAB_CHECKING_ACCOUNT_ID")}"
    )

    find_element(:class, "accounts-toolbar-file-import-transactions", 100) |> click()

    file = Download.list_files("*.ofx") |> Enum.at(0)
    session_id = Hound.current_session_id()
    element = find_element(:css, ".file-picker > input[type=file]")

    Hound.RequestUtils.make_req(:post, "session/#{session_id}/element/#{element}/value", %{
      value: ["#{file}"]
    })

    include_earlier_transactions_el =
      find_element(:css, ".import-preview-warning > .ynab-checkbox")

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

    find_element(
      :css,
      ".modal-import-review > .modal > .modal-fresh-footer > .ynab-button.primary"
    )
    |> click()

    find_element(
      :css,
      ".modal-import-successful > .modal > .modal-fresh-footer > .ynab-button.primary",
      20
    )
    |> click()

    File.rm!(file)
  end
end
