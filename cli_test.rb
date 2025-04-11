# frozen_string_literal: true

require 'minitest/autorun'
require 'pg'
require 'pry'

require_relative 'expenses'

ENV['EXPENSES_ENV'] = 'test'
class StringIO
  def getch
    self.getc
  end
end

# The CLITest class is responsible for testing the processing of CLI arguments
class CLITest < Minitest::Test
  def setup
    @cli = CLI.new
    # connect to the database
    @db = PG.connect(dbname: 'expenses_test')

    # clear any existing data
    @db.exec('DELETE FROM expenses')

    # initialize your application class
    @application = ExpenseData.new
  end

  def teardown
    @db.close
  end

  def test_adding_expense_with_valid_amount_and_memo
    assert_output(/^The expense has been added successfully.\n$/) { @cli.run(%w[add 1000.00 cheap car]) }
  end

  def test_adding_expense_with_empty_amount
    assert_output(/^Amount cannot be empty.\n$/) { @cli.run(%w[add]) }
  end

  def test_adding_expense_with_invalid_amount
    assert_output(/^Invalid amount format\. Use format like\n2341.23\n$/) { @cli.run(%w[add 23412341243.123 Pencil]) }
  end

  def test_adding_expense_with_empty_memo
    assert_output(/^Memo cannot be empty.\n$/) { @cli.run(%w[add 234.21]) }
  end

  def test_adding_expense_with_invalid_memo_format
    assert_output(/^Invalid memo format.$/) { @cli.run(%w[add 234.21 hello hello world]) }
  end

  def test_searching_with_valid_memo
    @application.add_new_expense('1000.00', 'cheap car')
    assert_output(/cheap car/) { @cli.run(%w[search cheap car]) }
  end

  def test_searching_with_valid_memo_not_recorded_in_database
    assert_output(/^No record found for this expense.$/) { @cli.run(%w[search william guiraud]) }
  end

  def test_searching_with_empty_memo
    assert_output(/^Memo cannot be empty.\n$/) { @cli.run(%w[search]) }
  end

  def test_searching_with_invalid_memo
    assert_output(/^Invalid memo format.\n$/) { @cli.run(%w[search hello world hello]) }
  end

  def test_deleting_expense_with_empty_id
    @application.add_new_expense('21.32', 'oil filter')
    assert_output(/^The id cannot be empty.\n/) { @cli.run(%w[delete]) }
  end

  def test_deleting_expense_with_invalid_id
    @application.add_new_expense('21.32', 'oil filter')
    assert_output(/^Invalid id format.\n$/) { @cli.run(%w[delete abc]) }
  end

  def test_removing_all_expenses_with_arguments
    @application.add_new_expense('21.32', 'oil filter')
    @application.add_new_expense('9921.32', 'cheap car')
    @application.add_new_expense('4231.32', 'cheap bike')
    assert_output(/^The clear command doesn't take any arguments.\n$/) { @cli.run(%w[clear all]) }
    assert_output(/^The clear command doesn't take any arguments\.\n$/) { @cli.run(%w[clear 23423]) }
  end

  def test_removing_all_expenses_without_arguments_and_n_as_sure
    @application.add_new_expense('21.32', 'oil filter')
    @application.add_new_expense('9921.32', 'cheap car')
    @application.add_new_expense('4231.32', 'cheap bike')

    original_stdin = $stdin
    $stdin = StringIO.new("n")
    begin
    assert_output(%r{^This will remove all expenses\. Are you sure\? \(y/n\)$}) { @cli.run(%w[clear]) }
    ensure
      $stdin = original_stdin
    end

  end

  def test_removing_all_expenses_without_arguments_and_y_as_sure
    @application.add_new_expense('21.32', 'oil filter')
    @application.add_new_expense('9921.32', 'cheap car')
    @application.add_new_expense('4231.32', 'cheap bike')

    original_stdin = $stdin
    $stdin = StringIO.new("y")
    begin
      assert_output(%r{^This will remove all expenses\. Are you sure\? \(y/n\)$}) { @cli.run(%w[clear]) }
    ensure
      $stdin = original_stdin
    end

  end

end
