defmodule Derp do
  use Application.Behaviour

  def start(_, _) do
    :error_logger.delete_report_handler :error_logger_tty_h
    :error_logger.add_report_handler __MODULE__.TTY

    { :ok, Process.whereis(:error_logger) }
  end

  def stop(_) do
    :error_logger.delete_report_handler __MODULE__.TTY
    :error_logger.add_report_handler :error_logger_tty_h
  end
end
