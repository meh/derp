defmodule Derp.TTY do
  use GenEvent.Behaviour

  defp header(title, pid) do
    use DateTime

    "== #{title} for #{inspect pid} at #{DateTime.now |> DateTime.format %t"Y-m-d H:i:s"f} ==\r\n"
  end

  defp print(leader, color, header, report) do
    report = if report |> is_binary do
      report
    else
      inspect(report, pretty: true)
    end

    IO.puts leader, IO.ANSI.escape("%{#{color}}" <> header <> report, leader)
  end

  defp print(leader, color, header, format, data) do
    report = :io_lib.format(format, data)

    IO.puts leader, IO.ANSI.escape("%{#{color}}" <> header <> String.from_char_list!(report), leader)
  end

  def handle_event({ :error, leader, { pid, format, data } }, _state) do
    print leader, :red, header("Error", pid), format, data

    { :ok, _state }
  end

  def handle_event({ :error_report, leader, { pid, :std_error, report } }, _state) do
    print leader, :red, header("Error Report", pid), report

    { :ok, _state }
  end

  def handle_event({ :warning_msg, leader, { pid, format, data } }, _state) do
    print leader, :yellow, header("Warning", pid), format, data

    { :ok, _state }
  end

  def handle_event({ :warning_report, leader, { pid, :std_warning, report } }, _state) do
    print leader, :yellow, header("Warning Report", pid), report

    { :ok, _state }
  end

  def handle_event({ :info_report, leader, { pid, :std_info, report } }, _state) do
    print leader, :green, header("Info Report", pid), report

    { :ok, _state }
  end

  def handle_event({ :info_msg, leader, { pid, format, data } }, _state) do
    print leader, :green, header("Warning", pid), format, data

    { :ok, _state }
  end

  def handle_event(_, _state) do
    { :ok, _state }
  end
end
