defmodule Itauynab.Download do

  import Hound.RequestUtils

  @download_path Path.join([File.cwd!(), "tmp/downloads"])

  def set_download_path do
    session_id = Hound.current_session_id()

    make_req(
      :post,
      "session/#{session_id}/chromium/send_command",
      %{
        cmd: "Page.setDownloadBehavior",
        params: %{behavior: "allow", downloadPath: @download_path}
      }
    )

    clear_downloads()
  end

  def clear_downloads do
    File.rm_rf(@download_path)
  end

  def wait_for_download!(filename, retries \\ 5, wait_time \\ 1000) do
    IO.puts("Waiting for file #{filename} in #{@download_path}...")

    count_files =
      @download_path
      |> Path.join(filename)
      |> Path.wildcard()
      |> Enum.count()

    unless(count_files != 0) do
      if retries > 0 do
        Process.sleep(wait_time)
        wait_for_download!(filename, retries - 1, wait_time)
      else
        raise "File not found in #{@download_path}"
      end
    end

  end
end
