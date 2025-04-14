# frozen_string_literal: true

require 'minitest/autorun'
require 'pg'
require 'pry'

ENV['EXPENSES_ENV'] = 'test'

require_relative 'expenses'

# The ExpenseDataTest class is responsible for testing:
# - communication with the PostgreSQL database
# - displaying and formating PG::Result objects
class ExpenseDateTest < Minitest::Test
  def setup
    @application = ExpenseData.new
  end

  def teardown
    @application.delete_all_expenses_from_database
    @application.reset_sequence
    @application.close
  end

  def test_list_expenses
    @application.add_new_expense('14.56', 'Pencils')
    @application.add_new_expense('3.29', 'Coffee')
    @application.add_new_expense('49.99', 'Text Editor')
    @application.add_new_expense('3.29', 'More Coffee')
    output = <<~list
    There are 4 expenses.
      1 | 2025-04-14 |        14.56 | Pencils
      2 | 2025-04-14 |         3.29 | Coffee
      3 | 2025-04-14 |        49.99 | Text Editor
      4 | 2025-04-14 |         3.29 | More Coffee
    --------------------------------------------------
    Total                     71.13
    list
    assert_output(output) { @application.list_expenses }
  end

  def test_list_one_expense
    @application.add_new_expense('100.00', 'car rental')
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |       100.00 | car rental
    --------------------------------------------------
    Total                    100.00
    list
    assert_output(output) { @application.list_expenses }
  end


  def test_display_help
    assert_output(/Commands:/) { @application.display_help }
  end

  def test_add_new_expense
    @application.add_new_expense('5000.00', 'France trip')
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |      5000.00 | France trip
    --------------------------------------------------
    Total                   5000.00
    list
    assert_output(output) { @application.list_expenses }
  end

  def test_add_new_potentially_dangerous_expense
    @application.add_new_expense('5000.00', "Gas for Karen's Car")
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |      5000.00 | Gas for Karen's Car
    --------------------------------------------------
    Total                   5000.00
    list
    assert_output(output) { @application.list_expenses }
  end

  def test_search_expense
    @application.add_new_expense('100.00', 'car rental')
    @application.search_expenses('car rental')
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |       100.00 | car rental
    --------------------------------------------------
    Total                    100.00
    list
    assert_output(output) { @application.list_expenses }
  end

  def test_deleting_valid_expense_id
    @application.add_new_expense('21.32', 'oil filter')
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |        21.32 | oil filter
    --------------------------------------------------
    Total                     21.32
    list
    assert_output(output) { @application.list_expenses }
    assert_output(/The following expense has been deleted:/) { @application.delete_expense('1') }
  end

  def test_deleting_expense_id_not_found
    @application.add_new_expense('21.32', 'oil filter')
    output = <<~list
    There is 1 expense.
      1 | 2025-04-14 |        21.32 | oil filter
    --------------------------------------------------
    Total                     21.32
    list
    assert_output(output) { @application.list_expenses }
    assert_output(/The expense with id 2 doesn't exist in the database./) {
      @application.delete_expense('2') }
  end
end
