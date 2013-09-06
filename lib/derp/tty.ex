defmodule Derp.TTY do
  use GenEvent.Behaviour

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n),             do: integer_to_binary(n)

  defp header(title, pid) do
    case :calendar.now_to_local_time(:erlang.now) do
      { { year, month, day }, { hour, minute, second } } ->
        "== #{title} for #{inspect pid} at #{year}-#{month |> pad}-#{day |> pad} #{hour |> pad}:#{minute |> pad}:#{second |> pad} ==\r\n"
    end
  end

  defp print(leader, color, header, format, data) do
    report = :io_lib.format(format, data)

    IO.puts leader, IO.ANSI.escape("%{#{color}}" <> header <> String.from_char_list!(report), leader)
  end

  defp print(leader, color, header, report) do
    report = if report |> is_binary do
      report
    else
      inspect(report, pretty: true)
    end

    IO.puts leader, IO.ANSI.escape("%{#{color}}" <> header <> report, leader)
  end

  defp print(:gen_server, leader, [name, msg, state, reason]) do
    header       = header("Generic Server Error", name)
    last_message = "-- Last Message: #{inspect msg, pretty: true}\r\n"
    state        = "-- State: #{inspect state, pretty: true}\r\n"
    reason       = "-- Reason: #{inspect reason, pretty: true}\r\n"

    IO.puts leader, IO.ANSI.escape("%{red}" <> header <> last_message <> state <> reason, leader)
  end

  @gen_server "** Generic server ~p terminating \n" <>
              "** Last message in was ~p~n" <>
              "** When Server state == ~p~n" <>
              "** Reason for termination == ~n** ~p~n" |> String.to_char_list!

  def handle_event({ :error, leader, { _pid, @gen_server, data } }, _state) do
    print :gen_server, leader, data
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
