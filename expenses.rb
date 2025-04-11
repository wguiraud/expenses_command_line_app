#! /usr/bin/env ruby
# frozen_string_literal: true

require 'pg'
require 'date'
require 'pry'
require 'io/console'

# Rails style configuration module
module ExpenseConfig
  DATABASE_NAME = 'expense'
  DATABASE_TEST_NAME = 'expenses_test'

  def self.database_name
    ENV['EXPENSES_ENV'] == 'test' ? DATABASE_TEST_NAME : DATABASE_NAME
  end
end

# Class responsible for communicating with database and displaying/formatting
# PG::Result objects
class ExpenseData
  def initialize
    @db = connect_to_database
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

  def search_expenses(memo)
    search_specific_expense(memo)
  end

  def delete_expense(id)
    remove_expense(id)
  end

  def close
    @db.close
  end

  def delete_all_expenses_from_database
    @db.exec('DELETE FROM expenses;')
    puts "All expenses have been deleted."
  end

  def reset_sequence
    @db.exec('ALTER SEQUENCE expenses_id_seq RESTART WITH 1')
  end

  attr_reader :db

  private

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
    table_name = db.quote_ident('expenses')
    result = db.exec("SELECT * FROM #{table_name}")
    if result.cmd_tuples > 0
      format_result(result)
    else
      puts "No expenses found."
    end
  rescue PG::Error => e
    puts e.message
    exit(1)
  end

  def execute_query(query, params)
    db.exec_params(query, params)
  end

  def save_expense(amount, preprocessed_memo)
    query = "INSERT INTO expenses (amount, memo, created_on) VALUES ($1, $2,
$3);"
    params = %W[#{amount} #{preprocessed_memo} #{Date.today}]

    execute_query(query, params)
    puts 'The expense has been added successfully.'
  rescue PG::Error => e
    puts "Error adding expense: #{e.message}"
  end

  def search_specific_expense(memo)
    table_name = db.quote_ident('expenses')
    query = "SELECT * FROM #{table_name} WHERE memo ILIKE $1"
    params = [memo]

    result = execute_query(query, params)

    if result.values.empty?
      puts 'No record found for this expense.'
    else
      format_result(result)
    end
  rescue PG::Error => e
    puts e.message
    exit(1)
  end

  def remove_expense(id)
    table_name = db.quote_ident('expenses')
    query = "SELECT * FROM #{table_name} WHERE id = $1"
    params = [id.to_s]

    result = execute_query(query, params)

    if result.cmd_tuples == 1
      expense_to_delete = result

      query = "DELETE FROM #{table_name} WHERE id = $1"
      execute_query(query, params)

      puts 'The following expense has been deleted:'
      format_result(expense_to_delete)
    else
      puts "The expense with id #{id} doesn't exist in the database."
    end
  rescue PG::Error => e
    puts "Error removing expense: #{e.message}"
  end

  def format_result(result)
    result.each do |tuple|
      columns = [tuple['id'].rjust(3),
                 tuple['created_on'].rjust(10),
                 tuple['amount'].rjust(12),
                 tuple['memo']]
      puts columns.join(' | ')
    end
  end
end

# Class responsible for processing CLI commands and arguments
class CLI
  def initialize
    @application = ExpenseData.new
  end

  def run(arguments = ARGV)
    command = arguments.shift

    case command
    when 'list' then @application.list_expenses
    when 'add' then handle_add_command(arguments)
    when 'search' then handle_search_command(arguments)
    when 'delete' then handle_delete_command(arguments)
    when 'clear' then handle_clear_command(arguments)
    else
      @application.display_help
    end
  end

  private

  def handle_add_command(arguments)
    amount = arguments[0]
    memo = arguments[1..]

    amount, preprocessed_memo = process_new_expense_input(amount, memo)
    valid_new_expense = validate_new_expense(amount, preprocessed_memo)

    if valid_new_expense[:valid]
      @application.add_new_expense(amount, preprocessed_memo)
    else
      puts valid_new_expense[:error]
    end
  end

  def handle_search_command(arguments)
    memo = arguments.join(' ')
    valid_search_memo = validate_search(memo)

    if valid_search_memo[:valid]
      @application.search_expenses(memo)
    else
      puts valid_search_memo[:error]
    end
  end

  def handle_delete_command(arguments)
    id = arguments[0]
    valid_id = validate_id(id)

    if valid_id[:valid]
      @application.delete_expense(id)
    else
      puts valid_id[:error]
    end
  end

  def handle_clear_command(arguments)
    if arguments.empty?
      puts 'This will remove all expenses. Are you sure? (y/n)'
      handle_yes_no_command
    else
      puts "The clear command doesn't take any arguments."
    end
  end

  def handle_yes_no_command
    yes_or_no = $stdin.getch
    if yes_or_no == "y"
      @application.delete_all_expenses_from_database
    elsif yes_or_no == "n"
      nil
    end
  end

  def process_new_expense_input(amount, memo)
    processed_memo = memo.is_a?(Array) ? memo.join(' ') : memo
    [amount, processed_memo]
  end

  def validate_new_expense(preprocessed_amount, preprocessed_memo)
    return { valid: false, error: 'Amount cannot be empty.' } if
      preprocessed_amount.nil? || preprocessed_amount.empty?
    return { valid: false, error: 'Memo cannot be empty.' } if
      preprocessed_memo.nil? || preprocessed_memo.empty?

    if invalid_amount?(preprocessed_amount)
      return { valid: false, error: "Invalid amount format. Use format like
2341.23" }
    end

    return { valid: false, error: 'Invalid memo format.' } if
      invalid_memo?(preprocessed_memo)

    { valid: true }
  end

  def validate_search(memo)
    return { valid: false, error: 'Memo cannot be empty.' } if memo.empty?
    return { valid: false, error: 'Invalid memo format.' } if invalid_memo?(memo)

    { valid: true }
  end

  def validate_id(id)
    return { valid: false, error: 'The id cannot be empty.' } if id.nil? ||
                                                                 id.empty?
    return { valid: false, error: 'Invalid id format.' } if invalid_id?(id)

    { valid: true }
  end

  def invalid_id?(id)
    !id.match?(/^[1-9][0-9]*$/)
  end

  def invalid_amount?(amount)
    !amount.match?(/^[0-9]{1,4}\.[0-9]{1,2}$/)
  end

  def invalid_memo?(memo)
    !memo.match?(/^[a-zA-Z]{1,20} ?[a-zA-Z]{0,20}$/)
  end
end

CLI.new.run
