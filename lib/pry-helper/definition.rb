require 'pry-helper/concerns'
require 'pry-helper/vd'

module PryHelper
  module Extension
    extend ActiveSupport::Concern

    def t
      puts Terminal::Table.new { |t|
        v.each { |row| t << (row || :separator) }
      }
    end

    def vd
      VD.new do |vd|
        vd << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
        self.class.connection.columns(self.class.table_name).each do |column|
          vd << [column.name, read_attribute(column.name), column.sql_type, column.comment || '']
        end
      end
    end

    def v
      t = []
      t << ['Attribute Name', 'Attribute Value', 'SQL Type', 'Comment']
      t << nil
      self.class.connection.columns(self.class.table_name).each do |column|
        t << [column.name, read_attribute(column.name), column.sql_type, column.comment || '']
      end
      t
    end

    def to_insert_sql
      self.class.to_insert_sql([self])
    end

    def to_upsert_sql
      self.class.to_upsert_sql([self])
    end

    def write_csv(filename, *fields, **options)
      [self].write_csv(filename, *fields, **options)
    end

    def write_excel(filename, *fields, **options)
      [self].write_excel(filename, *fields, **options)
    end

    def dump(filename, batch_size=500)
      [self].dump(filename, batch_size)
    end

    included do
    end

    class_methods do
      def t
        table_name = Commands::Table::get_table_name(name)
        puts "\nTable: #{table_name}"
        puts Commands::Table::table_info_table(table_name)
      end

      def vd
        table_name = Commands::Table::get_table_name(name)
        Commands::VD::table_info_vd(table_name)
        nil
      end

      def v
        table_name = Commands::Table::get_table_name(name)
        Commands::Table::table_info(table_name)
      end
      def to_insert_sql(records, batch_size=1)
        to_sql(records, :skip, batch_size)
      end

      def to_upsert_sql(records, batch_size=1)
        to_sql(records, :update, batch_size)
      end

      def to_sql(records, on_duplicate, batch_size)
        records.in_groups_of(batch_size, false).map do |group|
          ActiveRecord::InsertAll.new(self, group.map(&:attributes), on_duplicate: on_duplicate).send(:to_sql) + ';'
        end.join("\n")
      end

      def to_create_sql
        ActiveRecord::Base.connection.exec_query("show create table #{table_name}").rows.last.last
      end

      def dump(filename, no_create_table=false)
        PryHelper::Mysqldump.new.dump_table(filename, table_name, no_create_table)
      end
    end
  end

  class Definition
    class << self
      def models
        @@models ||= []
      end
    end

    def initialize
      @@models = []

      ActiveRecord::Base.connection.tap do |conn|
        defined_models = ::ApplicationRecord.descendants
        tables = conn.tables
        if conn.adapter_name == 'Mysql2'
          conn.define_singleton_method(:dump) do |filename, no_create_db=false|
            PryHelper::Mysqldump.new.dump_database(filename, no_create_db)
          end
          require 'pry-helper/ext/active_record/connection_adapters/abstract_mysql_adapter'
          comments = conn.table_comment_of_tables(tables)
          primary_keys = conn.primary_keys_of_tables(tables)
        else
          comments = tables.map { |t| [t, conn.table_comment(t)] }.to_h
          primary_keys = tables.map { |t| [t, conn.primary_keys(t)] }.to_h
        end

        ApplicationRecord.include(PryHelper::Extension)

        tables.each do |table_name|
          table_comment = comments[table_name]
          primary_keys[table_name].tap do |pkey|
            table_name.camelize.tap do |const_name|
              const_name = 'Modul' if const_name == 'Module'
              const_name = 'Clazz' if const_name == 'Class'
              if model_class = defined_models.find { |m| m.table_name == table_name }
                model_class.tap do |clazz|
                  model_class.name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                    abbr_const = nil
                    9.times do |idx|
                      abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                      unless Object.const_defined?(abbr)
                        Object.const_set abbr, model_class
                        abbr_const = abbr
                        break
                      end
                    end

                    @@models << {
                      model: model_class,
                      abbr: abbr_const,
                      table: table_name,
                      comment: table_comment
                    }
                  end
                end
              else
                Class.new(::ApplicationRecord) do
                  if pkey.is_a?(Array) && pkey.size > 1
                    self.primary_keys = pkey
                  else
                    self.primary_key = pkey&.first
                  end
                  self.table_name = table_name
                  self.inheritance_column = nil
                  ActiveRecord.default_timezone = :local
                end.tap do |clazz|
                  Object.const_set(const_name, clazz).tap do |const|
                    const_name.gsub(/[a-z]*/, '').tap do |bare_abbr|
                      abbr_const = nil
                      9.times do |idx|
                        abbr = idx.zero? ? bare_abbr : "#{bare_abbr}#{idx+1}"
                        unless Object.const_defined?(abbr)
                          Object.const_set abbr, const
                          abbr_const = abbr
                          break
                        end
                      end

                      @@models << {
                        model: const,
                        abbr: abbr_const,
                        table: table_name,
                        comment: table_comment
                      }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    ::ActiveRecord::Relation.class_eval do
      def t(*attrs, **options)
        records.t(*attrs, **options)
      end

      def vd(*attrs, **options)
        records.vd(*attrs, **options)
      end

      def v
        records.v
      end

      def a
        to_a
      end

      def write_csv(filename, *fields, **options)
        records.write_csv(filename, *fields, **options)
      end

      def write_excel(filename, *fields, **options)
        records.write_excel(filename, *fields, **options)
      end

      def dump(filename, batch_size=500)
        records.dump(filename, batch_size)
      end
    end

    ::ActiveRecord::Result.class_eval do
      def t(*attrs, **options)
        to_a.t(*attrs, **options)
      end

      def vd(*attrs, **options)
        to_a.vd(*attrs, **options)
      end

      def v
        to_a.v
      end

      def a
        to_a
      end

      def write_csv(filename, *fields, **options)
        to_a.write_csv(filename, *fields, **options)
      end

      def write_excel(filename, *fields, **options)
        to_a.write_excel(filename, *fields, **options)
      end
    end
  end
end
