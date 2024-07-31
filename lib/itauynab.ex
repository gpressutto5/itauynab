defmodule Itauynab do
  @moduledoc """
  Documentation for `Itauynab`.
  """

  use Hound.Helpers
  alias Itauynab.Download

  def run do
    Envy.auto_load()
    Application.ensure_all_started(:hound)
    start_browser()
    Download.set_download_path()

    try do
      open_itau_and_login()
      download_ofx_file()
      # download_xls_files()
      # convert_xls_to_csv()
      open_ynab_and_login()
      upload_ofx_file()
      # upload_csv_files()
    after
      stop_browser()
    end
  end

  # Login
  defp open_itau_and_login do
    # set_window_size(current_window_handle(), 0, 0)

    navigate_to("https://www.itau.com.br/")

    if Regex.match?(~r/Access Denied/, visible_page_text()) do
      refresh_page()
    end

    # LOGIN
    find_element(:id, "marco-civil-btn-ok") |> click()

    find_element(:id, "open-modal-more-access-zoom") |> click()

    fill_field({:id, "idl-more-access-input-agency"}, System.get_env("ITAU_AGENCIA"))
    fill_field({:id, "idl-more-access-input-account"}, System.get_env("ITAU_CONTA"))

    find_element(:id, "idl-more-access-submit-button") |> click()

    find_element(:id, "frmKey", 40)

    # PASSWORD
    System.get_env("ITAU_SENHA")
    |> String.graphemes()
    |> Enum.each(
      &execute_script(
        ~s[Array.from(document.querySelector('.teclas').childNodes).find(e => e?.text?.includes("#{&1}")).click()]
      )
    )

    find_element(:id, "acessar") |> click()
  end

  defp open_ynab_and_login do
    navigate_to("https://app.ynab.com/users/sign_in")

    fill_field({:id, "request_data_email"}, System.get_env("YNAB_EMAIL"))
    Process.sleep(100)
    fill_field({:id, "request_data_password"}, System.get_env("YNAB_PASSWORD"))
    Process.sleep(100)
    find_element(:id, "login") |> click()

    find_element(:class, "user-logged-in", 50)
  end

  # OFX
  defp download_ofx_file do
    find_element(:id, "HomeLogo", 40) |> click()

    find_element(:id, "saldo-extrato-card-accordion", 40) |> click()

    find_element(
      :xpath,
      "//*[@id=\"content-saldo-extrato-card-accordion\"]/div[1]/div[2]/contas-saldo-balance/div/div[2]/button"
    )
    |> click()

    Process.sleep(5000)

    find_element(:id, "periodoFiltro") |> click()
    find_element(:xpath, "//*[@id=\"periodoFiltroList\"]/li[4]") |> click()

    Process.sleep(3000)

    execute_script(~s[exportarExtratoArquivo('formExportarExtrato', 'ofx');])
    Download.wait_for_download!("*.ofx")
  end

  defp upload_ofx_file do
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

  # XLS
  defp download_xls_files() do
    find_element(:id, "HomeLogo", 40) |> click()

    find_element(:id, "cartao-card-accordion", 40) |> click()

    # The card we click doesn't matter as it will always open the first one
    find_element(
      :xpath,
      "//*[@id=\"content-cartao-card-accordion\"]/div[1]/table/tbody/tr[1]/td[1]/div/div[1]/a"
    )
    |> click()

    Process.sleep(5000)

    # find_element(:id, "exp_button") |> click()
    last_four = System.get_env("ITAU_CARD_LAST_FOUR")

    # execute_script(
    #   ~s[Array.from(document.querySelectorAll('.selecao__opcao')).find(e => e?.innerText?.includes("#{last_four}")).click()]
    # )

    # Process.sleep(3000)

    a =
      Jason.decode!(
        execute_script(
          ~s[return(JSON.stringify(angular.element(document.getElementById("appController")).scope().ac))]
        )
      )

    take_screenshot("1.png")
  end

  # Browser
  defp start_browser do
    Hound.start_session(additional_capabilities: %{browserName: "chrome"})
  end

  defp stop_browser do
    Hound.end_session()
  end
end
