defmodule Derp.TTY do
  import Kernel, except: [inspect: 1]

  use GenEvent.Behaviour

  defp inspect(value) do
    try do
      Kernel.inspect(value, pretty: true)
    rescue _ ->
      :io_lib.format('~p', [value]) |> String.from_char_list!
    end
  end

  def pid(name) when name |> is_pid do
    case Process.info(name, :registered_name) do
      { :registered_name, name } ->
        name |> to_string

      _ ->
        name |> inspect
    end
  end

  def pid(name) when name |> is_atom do
    case atom_to_binary(name) do
      "Elixir." <> name ->
        name

      name ->
        name
    end
  end

  def pid(name) when name |> is_list do
    ['Elixir.' | name] = name

    name |> String.from_char_list!
  end

  defp header(title) do
    "== #{title} at #{date} ==\r\n"
  end

  defp header(title, pid) do
    "== #{title} from #{pid(pid)} at #{date} ==\r\n"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n),             do: integer_to_binary(n)

  defp date do
    case :calendar.now_to_local_time(:erlang.now) do
      { { year, month, day }, { hour, minute, second } } ->
        "#{year}-#{month |> pad}-#{day |> pad} #{hour |> pad}:#{minute |> pad}:#{second |> pad}"
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
      inspect report
    end

    IO.puts leader, IO.ANSI.escape("%{#{color}}" <> header <> report, leader)
  end

  defp print(:gen_server, leader, [name, msg, state, reason]) do
    header       = header("Generic Server Error", name)
    last_message = "-- Last Message: #{inspect msg}\r\n"
    state        = "-- State: #{inspect state}\r\n"
    reason       = "-- Reason: #{inspect reason}\r\n"

    IO.puts leader, IO.ANSI.escape("%{red}" <> header <> last_message <> state <> reason, leader)
  end

  defp print(:gen_event, leader, [handler, name, last, state, reason]) do
    header       = header("Generic Event Handler Error from #{pid(handler)} installed in #{name}")
    last_message = "-- Last Event: #{inspect last}\r\n"
    state        = "-- State: #{inspect state}\r\n"
    reason       = "-- Reason: #{inspect reason}\r\n"

    IO.puts leader, IO.ANSI.escape("%{red}" <> header <> last_message <> state <> reason, leader)
  end

  @gen_server "** Generic server ~p terminating \n" <>
              "** Last message in was ~p~n" <>
              "** When Server state == ~p~n" <>
              "** Reason for termination == ~n** ~p~n" |> String.to_char_list!

  def handle_event({ :error, leader, { _pid, @gen_server, data } }, _state) do
    print :gen_server, leader, data

    { :ok, _state }
  end

  @gen_event "** gen_event handler ~p crashed.~n" <>
             "** Was installed in ~p~n" <>
             "** Last event was: ~p~n" <>
             "** When handler state == ~p~n" <>
             "** Reason == ~p~n" |> String.to_char_list!

  def handle_event({ :error, leader, { _pid, @gen_event, data } }, _state) do
    print :gen_event, leader, data

    { :ok, _state }
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
