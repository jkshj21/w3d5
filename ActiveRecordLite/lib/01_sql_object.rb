require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL)
    
      SELECT
          *
      FROM
        #{self.table_name}
    SQL

    @attributes = cols[1..-1]
    @columns = cols.first.map!{|e| e.to_sym}
  end


  def self.finalize!
    self.columns.each do |column_key|
      define_method(column_key) do
        self.attributes[column_key] # double
      end
      define_method("#{column_key}=") do |value|
        self.attributes[column_key] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    table = "#{self}".tableize
    table = table =='humen' ? "humans" : table
  end

  def self.all
    table = DBConnection.execute2(<<-SQL)
      SELECT
          *
      FROM
        #{self.table_name}
    SQL

    parse_all(table[1..-1])
  end

  def self.parse_all(results)
    results.map{ |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name.to_sym}'" unless self.class.columns.include?(attr_name.to_sym) #class method
      self.send("#{attr_name.to_sym}=", value)
    end

  end

  def attributes
    @attributes = @attributes ? @attributes: {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update

  end

  def save

  end
end
