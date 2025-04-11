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
  #    #connect to the database
  def setup
    @application = ExpenseData.new
  end

  def teardown
    @application.delete_all_expenses_from_database
    @application.reset_sequence
    @application.close
  end

  def test_list_expenses
    @application.add_new_expense('100.00', 'car rental')
    assert_output(/100.00 | car rental/) { @application.list_expenses }
  end

  def test_display_help
    assert_output(/Commands:/) { @application.display_help }
  end

  def test_add_new_expense
    @application.add_new_expense('5000.00', 'France trip')
    assert_output(/5000.00 | France trip/) { @application.list_expenses }
  end

  def test_add_new_potentially_dangerous_expense
    @application.add_new_expense('5000.00', "Gas for Karen's Car")
    assert_output(/5000.00 | Gas for Karen's Car/) { @application.list_expenses }
  end

  def test_search_expense
    @application.add_new_expense('100.00', 'car rental')
    @application.search_expenses('car rental')
    assert_output(/100.00 | car rental/) { @application.list_expenses }
  end

  def test_deleting_valid_expense_id
    @application.add_new_expense('21.32', 'oil filter')
    assert_output(/21.32 | oil filter/) { @application.list_expenses }
    assert_output(/The following expense has been deleted:/) { @application.delete_expense('1') }
  end

  def test_deleting_expense_id_not_found
    @application.add_new_expense('21.32', 'oil filter')
    assert_output(/21.32 | oil filter/) { @application.list_expenses }
    assert_output(/The expense with id 2 doesn't exist in the database./) { @application.delete_expense('2') }
  end
end
