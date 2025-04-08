require 'minitest/autorun'
require 'pg'
require 'pry'

require_relative 'expenses'

ENV["EXPENSES_ENV"] = "test"

class CLITest < Minitest::Test
  def setup
    @cli = CLI.new
  end

  def test_display_help
    assert_output(/An expenses recording system\n/) { @cli.run }
  end

  def test_running_adding_empty_amount
    assert_output(/Amount cannot be empty/) { @cli.run(["add", "", "Pencil"]) }
  end

  def test_running_adding_invalid_amount
    assert_output(/Invalid amount format\. Use format like\n2341.23\n/) { @cli.run(["add", "23412341243.123", "Pencil"]) }
  end

  def test_running_adding_empty_memo
    assert_output(/Memo cannot be empty/) { @cli.run(["add", "234.21", ""]) }
  end

  def test_running_adding_invalid_memo_format
    assert_output(/Invalid memo format/) { @cli.run(["add", "234.21", "hello hello world"]) }
  end
end