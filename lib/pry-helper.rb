if Rails.const_defined? 'Console'
  Pry.hooks.add_hook(:when_started, :pry_helper) do |output, binding, pry|
    require 'terminal-table'
    require 'table_print'
    require 'roo'
    require 'caxlsx'
    require 'csv'
    require "pry-helper/version"
    require 'pry-helper/id'
    require 'pry-helper/ext'
    require "pry-helper/mysqldump"
    require "pry-helper/vd"
    require 'pry-helper/definition'
    require 'pry-helper/commands'
    PryHelper::Definition.new
  end
end

module PryHelper
end
