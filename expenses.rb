#! /usr/bin/env ruby
require 'pg'
require 'date'
require 'pry'

module ExpenseConfig
  DATABASE_NAME = 'expense'
  DATABASE_TEST_NAME = 'expenses_test'

  def self.database_name
    ENV["EXPENSES_ENV"] == "test" ? DATABASE_TEST_NAME : DATABASE_NAME
  end
end

class ExpenseManager
  def initialize
    @db = connect_to_database
    at_exit { @db.close if @db }
  end

  def display_help
    puts <<~HELP
  An expenses recording system

  Commands:

  add AMOUNT MEMO - record a new expense
  clear - delete all expenses
  list - list all expenses
  delete NUMBER - remove expense with id NUMBER
  search QUERY - list expenses with a matching memo field
  HELP
  end

  def list_expenses
    read_expenses
  end

  def add_new_expense(amount, memo)
    save_expense(amount, memo)
  end

  def close
    @db.close
  end

  private
  attr_reader :db

  def connect_to_database
    PG.connect(dbname: ExpenseConfig.database_name)
  rescue PG::ConnectionBad => e
    puts e.message
    exit(1)
  rescue PG::Error => e
    puts e.message
    exit(1)
  end

  def read_expenses
    table_name = db.quote_ident("expenses")
    result = db.exec("SELECT * FROM #{table_name}")
    result.each do |tuple|
      columns = [ tuple["id"].rjust(3),
                  tuple["created_on"].rjust(10),
                  tuple["amount"].rjust(12),
                  tuple["memo"] ]
      puts columns.join(" | ")
    end
  rescue PG::Error => e
    puts e.message
    exit(1)
  end

  def execute_query(query, params)
    db.exec_params(query, params)
  end

  #  # Database-related method - only concerned with saving data
  def save_expense(amount, preprocessed_memo)
    query = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2,
$3);"
    params = ["#{amount}", "#{preprocessed_memo}", "#{Date.today}"]

    execute_query(query, params)
    puts "The expense has been added successfully."
  rescue PG::Error => e
    puts "Error adding expense: #{e.message}"
  end
end

class CLI
  def initialize
    @application = ExpenseManager.new
  end

  def run(arguments = ARGV)
    command = arguments[0]
    amount = arguments[1]
    memo = arguments[2..]

    amount, preprocessed_memo = preprocessed_input(amount, memo)
    valid_result = validate_expense(amount, preprocessed_memo)


    case command
    when 'list'
      @application.list_expenses
    when 'add'
      if valid_result[:valid]
        @application.add_new_expense(amount, preprocessed_memo)
      else
        puts valid_result[:error]
      end
    else
      @application.display_help
    end
  end

  private
  def preprocessed_input(amount, memo)
    processed_memo = memo.is_a?(Array) ? memo.join(" ") : memo
    [amount, processed_memo]
  end

  # Validation-related method - only concerned with validating inputs
  def validate_expense(preprocessed_amount, preprocessed_memo)
    return { valid: false, error: "Amount cannot be empty." } if
      preprocessed_amount.nil? || preprocessed_amount.empty?

    return { valid: false, error: "Memo cannot be empty." } if
      preprocessed_memo.nil? || preprocessed_memo.empty?

    return { valid: false, error: "Invalid amount format. Use format like
2341.23" } if invalid_amount?(preprocessed_amount)

    return { valid: false, error: "Invalid memo format" } if
      invalid_memo?(preprocessed_memo)

    { valid: true }
  end

  def invalid_amount?(amount)
    !amount.match?(/^[0-9]{1,4}\.[0-9]{1,2}$/)
  end

  def invalid_memo?(memo)
    !memo.match?(/^[a-zA-Z]{1,20} ?[a-zA-Z]{1,20}$/)
  end

end

CLI.new.run