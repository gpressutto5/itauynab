defmodule Itauynab.Itau do
  use Hound.Helpers
  alias Itauynab.Download
  import Itauynab.Helpers, only: [parse_amount: 1]
  require CSV

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

    Process.sleep(500)

    window_handles() |> List.last() |> focus_window()

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

    balance = find_element(:id, "saldo") |> visible_text() |> parse_amount()

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
    balance
  end

  def download_csv_file() do
    find_element(:id, "HomeLogo", 40) |> click()

    Process.sleep(3000)

    find_element(:id, "cartao-card-accordion") |> click()

    # The card we click doesn't matter as it will always open the first one
    find_element(
      :xpath,
      "//*[@id=\"content-cartao-card-accordion\"]/div[1]/table/tbody/tr[1]/td[1]/div/div[1]/a",
      40
    )
    |> click()

    Process.sleep(5000)

    last_four = System.get_env("ITAU_CARD_LAST_FOUR")

    execute_script(
      ~s[Array.from(document.querySelectorAll('.selecao__opcao')).find(e => e?.innerText?.includes("#{last_four}")).click()]
    )

    Process.sleep(3000)

    last_four
    |> parse_credit_card_transactions()

    execute_script(
      ~s[Array.from(document.querySelectorAll('.tab.abasButton')).find(e => e?.innerText?.includes("aberta")).click()]
    )

    balance =
      find_element(:css, ".c-category-status__total.aberta") |> visible_text() |> parse_amount()

    find_element(:css, ".icon-itaufonts_full_parcelamento") |> click()
    Process.sleep(3000)
    find_element(:name, "CORPO") |> focus_frame()
    find_element(:class, "TRNinputBTN", 40)
    Process.sleep(1000)

    execute_script(
      ~s[Array.from(document.querySelectorAll('.TRNinput')).find(e => e?.value?.includes("#{last_four}|")).click()]
    )

    find_element(:class, "TRNinputBTN") |> click()

    {{current_year, current_month, _}, _} = :calendar.local_time()
    final_month = current_month + 3
    final_year = current_year

    {final_month, final_year} =
      if final_month > 12 do
        {final_month - 12, final_year + 1}
      else
        {final_month, final_year}
      end

    find_element(:name, "Mes_Inicio") |> fill_field("#{current_month}")
    find_element(:name, "Ano_Inicial") |> fill_field("#{current_year}")
    find_element(:name, "Mes_Final") |> fill_field("#{final_month}")
    find_element(:name, "Ano_Final") |> fill_field("#{final_year}")
    Process.sleep(500)
    execute_script("continuar();")
    Process.sleep(1000)

    instalments_balance =
      case search_element(
             :xpath,
             "//*[@id=\"TRNcontainer01\"]/table[4]/tbody/tr/td/table[1]/tbody/tr/td/table/tbody/tr/td[1]/table/tbody/tr[2]/td"
           ) do
        {:error, _err} ->
          IO.puts("No instalments found")
          0

        {:ok, el} ->
          el |> visible_text() |> parse_amount()
      end

    balance + instalments_balance
  end

  defp parse_credit_card_transactions(last_four) do
    Path.join([File.cwd!(), "/lib/credit_card_script.js"])
    |> File.read!()
    |> execute_script([last_four])
    |> Jason.decode!()
    |> make_csv()
  end

  def make_csv(transactions) do
    csv =
      transactions
      |> Enum.map(fn transaction ->
        Enum.map(transaction, fn {key, value} ->
          {String.to_atom(key), value}
        end)
        |> Enum.into(%{})
      end)
      |> CSV.encode(headers: [date: "Date", payee: "Payee", outflow: "Outflow"])
      |> Enum.to_list()
      |> Enum.join()

    Path.join([Download.download_path(), "credit_card.csv"])
    |> File.write!(csv)
  end
end
