require 'minitest/autorun'
require 'pg'
require 'pry'

require_relative 'expenses'

ENV["EXPENSES_ENV"] = "test"

class ExpensesAppTest < Minitest::Test
  def setup
    #connect to the database
    @db = PG.connect(dbname: 'expenses_test')

    #clear any existing data
    @db.exec("DELETE FROM expenses")

    #initialize your application class
    @application = ExpenseManager.new
  end

  def teardown
    @db.close
  end

  def test_list_expenses
    @application.add_new_expense("100.00", "car rental")
    assert_output(/100.00 | car rental/) { @application.list_expenses }
  end

  def test_display_help
    assert_output(/Commands:/) { @application.display_help }
  end

  def test_add_new_expense
    @application.add_new_expense("5000.00", "France trip")
    assert_output(/5000.00 | France trip/) { @application.list_expenses }
  end

  def test_raises_bad_connection_error
    assert_raises(PG::ConnectionBad) { PG.connect(dbname: 'william') }
  end
end
