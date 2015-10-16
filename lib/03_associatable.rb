require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {foreign_key: "#{name}_id".to_sym,
                class_name: name.to_s.camelcase,
                primary_key: "id".to_sym
              }

    defaults = defaults.merge(options)

    defaults.each do |key, value|
      self.send("#{key}=", value)
    end

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {foreign_key: "#{self_class_name.downcase}_id".to_sym,
                class_name: name.singularize.camelcase,
                primary_key: "id".to_sym
              }

    defaults = defaults.merge(options)

    defaults.each do |key, value|
      self.send("#{key}=", value)
    end

  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(:name) do
      send(:foreign_key, options.foreign_key)
      send(:class_name, options.class_name)
      send(:primary_key, options.primary_key)
    end

  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
