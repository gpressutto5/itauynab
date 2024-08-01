defmodule Itauynab.Itau do
  use Hound.Helpers
  alias Itauynab.Download

  def open_and_login do
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

  def download_ofx_file do
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

  def download_xls_files() do
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
    _last_four = System.get_env("ITAU_CARD_LAST_FOUR")

    # execute_script(
    #   ~s[Array.from(document.querySelectorAll('.selecao__opcao')).find(e => e?.innerText?.includes("#{last_four}")).click()]
    # )

    # Process.sleep(3000)

    _a =
      Jason.decode!(
        execute_script(
          ~s[return(JSON.stringify(angular.element(document.getElementById("appController")).scope().ac))]
        )
      )

    take_screenshot("1.png")
  end
end
