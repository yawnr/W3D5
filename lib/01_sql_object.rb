require_relative 'db_connection'
# require_relative '02_searchable'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  # include Searchable

  def self.columns
    col_names = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    columns = []

    col_names.first.each do |col_name|
      columns << col_name.to_sym
    end

    columns
  end

  def self.finalize!
    columns.each do |column|
      send(:define_method, column) do
        attributes[column]
      end

      send(:define_method, "#{column}=") do |value|
        attributes[column] = value
      end
    end

    nil
  end

  @table_name = nil

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self.to_s.downcase.tableize}"
    @table_name
  end

  def self.all
    data = DBConnection.execute(<<-SQL)
            SELECT
              *
            FROM
              #{self.table_name}
          SQL

    parse_all(data)

  end

  def self.parse_all(results)
    parsed_results = []

    results.each do |result_hash|
      parsed_results << self.new(result_hash)
    end

    parsed_results
  end

  def self.find(id)
    result_hash = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    return nil if result_hash.empty?
    found = self.new(result_hash.first)
    found
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name)

      send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = "(#{self.class.columns.drop(1).join(", ")})"
    question_marks = "(#{(["?"] * (self.class.columns.count - 1)).join(", ")})"
    vals = self.attribute_values

    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES
        #{question_marks}
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = []

      self.class.columns.drop(1).each_with_index do |col|
        set_line << "#{col} = ?"
      end

    set_line_string = set_line.join(", ")
    vals = self.attribute_values
    id = vals.shift
    vals << id

    DBConnection.execute(<<-SQL, *vals)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line_string}
      WHERE
        id = ?
    SQL

  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end

end
