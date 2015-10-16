require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    vals = []
    where_arr = []

    params.each do |col, val|
      vals << val
      where_arr << "#{col} = ? "
    end

    where_string = where_arr.join("AND ")

    puts vals.to_s
    puts where_string

    results = DBConnection.execute(<<-SQL, *vals)
              SELECT
                *
              FROM
                #{self.table_name}
              WHERE
                #{where_string}
            SQL

    results.map { |result| self.new(result)}
  end
end

class SQLObject
  extend Searchable
end
