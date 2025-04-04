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

    #insert data into the database or create test fixtures
    sql = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2, $3)"
    @db.exec_params(sql, [14.56, "Test Pencils", Date.today])

    #initialize your application class
    @expense_manager = ExpenseManager.new
  end

  def teardown
    #clean up the test database after each test
    @db.close
  end

  def test_list_expenses
    #output = capture_io { @expense_manager.list_expenses }.first
    assert_output(/Test Pencils/) { @expense_manager.list_expenses }
    assert_output(/14.56/) { @expense_manager.list_expenses }

    #assert_match(/Test Pencils/, output)
    #assert_match(/14.56/, output)
  end

  def test_add_valid_expense




  end
end

