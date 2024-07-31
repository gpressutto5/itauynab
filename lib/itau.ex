defmodule Itauynab.Itau do
  use Hound.Helpers

  alias Itauynab.Download

  @base_url "https://www.itau.com.br/"

  def login do
    navigate_to(@base_url)

    if Regex.match?(~r/Access Denied/, visible_page_text()) do
      refresh_page()
    end

    find_element(:id, "marco-civil-btn-ok") |> click()

    find_element(:id, "open-modal-more-access-zoom") |> click()

    fill_field({:id, "idl-more-access-input-agency"}, System.fetch_env!("ITAU_AGENCIA"))
    fill_field({:id, "idl-more-access-input-account"}, System.fetch_env!("ITAU_CONTA"))

    find_element(:id, "idl-more-access-submit-button") |> click()

    find_element(
      :css,
      "#formTitularidade",
      40
    )

    find_element(
      :css,
      "#formTitularidade > div > div.col8 > div.modulo > div > div > ul > li:nth-child(1) > a"
    )
    |> click()

    find_element(:id, "frmKey", 40)

    System.fetch_env!("ITAU_SENHA")
    |> String.graphemes()
    |> Enum.each(
      &execute_script(
        ~s[Array.from(document.querySelector('.teclas').childNodes).find(e => e?.text?.includes("#{&1}")).click()]
      )
    )

    find_element(:id, "acessar") |> click()

    find_element(:id, "saldo-extrato-card-accordion", 40)
  end

  def download_ofx_file do
    find_element(:id, "saldo-extrato-card-accordion", 40) |> click()

    find_element(
      :xpath,
      "//*[@id=\"content-saldo-extrato-card-accordion\"]/div[1]/div[2]/contas-saldo-balance/div/div[2]/button"
    )
    |> click()

    Process.sleep(5000)

    find_element(:id, "periodoFiltro") |> click()
    find_element(:xpath, "//*[@id=\"periodoFiltroList\"]/li[1]") |> click()

    Process.sleep(3000)

    execute_script(~s[exportarExtratoArquivo('formExportarExtrato', 'ofx');])
    Download.wait_for_download!("*.ofx")
  end
end
