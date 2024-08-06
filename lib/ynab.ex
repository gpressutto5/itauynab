defmodule Itauynab.Ynab do
  use Hound.Helpers
  alias Itauynab.Download
  import Itauynab.Helpers, only: [parse_amount: 1]

  def open_and_login do
    navigate_to("https://app.ynab.com/users/sign_in")

    fill_field({:id, "request_data_email"}, System.get_env("YNAB_EMAIL"))
    Process.sleep(100)
    fill_field({:id, "request_data_password"}, System.get_env("YNAB_PASSWORD"))
    Process.sleep(100)
    find_element(:id, "login") |> click()

    find_element(:class, "user-logged-in", 50)
  end

  def upload_ofx_file(balance \\ nil) do
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

    include_earlier_transactions_el =
      search_element(:css, ".import-preview-warning > .ynab-checkbox")

    case include_earlier_transactions_el do
      {:error, _err} ->
        IO.puts("Element not found")

      {:ok, el} ->
        unless el |> has_class?("is-checked") do
          el |> click()
        end
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

    allowed_diff =
      case System.get_env("YNAB_CHECKING_ALLOWED_DIFF_PERCENTAGE") do
        nil -> 0
        str -> str |> String.to_float()
      end

    reconcile(balance, allowed_diff)
  end

  def reconcile(nil, _), do: nil

  def reconcile(balance, allowed_diff_percantage) when is_integer(balance) do
    IO.puts("Reconciling account balance (#{balance})")
    find_element(:class, "accounts-header-reconcile") |> click()
    find_element(:class, "modal-account-reconcile-no") |> click()

    execute_script(
      ~s[el = document.querySelector('.ynab-new-currency-input input'); el.value = ynab.formatCurrency(#{balance * 10});el.dispatchEvent(new Event('input', { bubbles: true }))]
    )

    find_element(:css, ".modal-account-reconcile-right-buttons button") |> click()

    adjsutment_label = search_element(:class, ".accounts-adjustment-label")

    case adjsutment_label do
      {:error, _err} ->
        nil

      {:ok, el} ->
        IO.puts("Adjusting balance")
        diff_balance = find_within_element(el, :tag, "strong") |> visible_text() |> parse_amount()

        current_balance =
          find_element(:css, ".accounts-header-balances-cleared > span")
          |> visible_text()
          |> parse_amount()

        case should_adjust(diff_balance, current_balance, allowed_diff_percantage) do
          true ->
            find_element(:css, ".accounts-adjustment button.ynab-button.primary") |> click()
            IO.puts("Balance adjust by #{diff_balance}")
        end

      false ->
        IO.puts("Balance not adjusted")
    end
  end

  def should_adjust(_, 0, _), do: false

  def should_adjust(diff_balance, current_balance, allowed_diff_percantage) do
    # get percentage diff
    percentage_diff = diff_balance / current_balance
    percentage_diff <= allowed_diff_percantage
  end

  def upload_csv_file do
    navigate_to(
      "https://app.ynab.com/#{System.get_env("YNAB_BUDGET_ID")}/accounts/#{System.get_env("YNAB_CREDIT_CARD_ACCOUNT_ID")}"
    )

    find_element(:class, "accounts-toolbar-file-import-transactions", 100) |> click()

    file = Download.list_files("*.csv") |> Enum.at(0)
    session_id = Hound.current_session_id()
    element = find_element(:css, ".file-picker > input[type=file]")

    Hound.RequestUtils.make_req(:post, "session/#{session_id}/element/#{element}/value", %{
      value: ["#{file}"]
    })

    include_earlier_transactions_el =
      search_element(:css, ".import-preview-warning > .ynab-checkbox")

    case include_earlier_transactions_el do
      {:error, _err} ->
        IO.puts("Element not found")

      {:ok, el} ->
        unless el |> has_class?("is-checked") do
          el |> click()
        end
    end

    swap_memo_with_payee_el = find_element(:class, "swap-memo-with-payee")

    if swap_memo_with_payee_el |> has_class?("is-checked") do
      swap_memo_with_payee_el |> click()
    end

    import_memos_el = find_element(:class, "import-memos")

    if import_memos_el |> has_class?("is-checked") do
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
