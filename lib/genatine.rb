require "genatine/version"
require 'active_support/inflector'
require 'colorize'

module Genatine
  class Genatine
    def self.generate(model_name, attrs=[], options={})
      generated = {}

      generated[:model] = generate_model(model_name, attrs)
      generated[:controller] = generate_controller(model_name)
      generated[:route] = generate_route(model_name)

      paths = {
        model: "app/models/#{model_name}.scala",
        controller: "app/controllers/#{model_name.pluralize}Controller.scala",
        route: "conf/routes"
      }
      paths.map {|k,v| FileUtils.mkdir_p(File.dirname(v)) unless File.exists?(v)}

      if options[:dry_run]
        puts "Model: #{paths[:model]}".bold.green, generated[:model]
        puts "Controller: #{paths[:controller]}".bold.green, generated[:controller]
        puts "In routes: #{paths[:route]}".bold.green, generated[:route]
      else
        paths.map do |k,v|
          if File.exists?(v) && k != :route
            $STDERR.puts "#{v} already exists and will not be overwritten".red
          else
            open(v, k == :route ? "a" : "w") { |f| f.puts(generated[k]) }
          end
        end
      end

    end

    private

    def self.generate_route(model_name)
      pluralized = model_name.capitalize.pluralize
      "->   /#{pluralized}    controller.#{pluralized}Controller"
    end

    def self.generate_controller(model_name)
      sample =<<-EOS
      package controllers

      import play.api._
      import play.api.mvc._

      import play.autosource.slick.SlickAutoSourceController
      import models.#{model_name}
      import play.api.libs.json.Json
      import models.Components.instance.#{model_name.pluralize}
      import play.api.db.slick.DBAction

      object #{model_name.pluralize}Controller extends SlickAutoSourceController[#{model_name}] {
      }
      EOS
    end

    def self.generate_model(model_name, attrs=[])
      sample =<<-EOS
      package models

      import slick.dao.{SlickDaoProfile, Entity}
      import play.api.libs.json.Json

      case class #{model_name}(
        #{attrs.map{|x| case_class(x) + ","}.join("\n")}
        id: Option[Long] = None
      ) extends Entity[#{model_name}] {
        def withId(id: Long): #{model_name} = copy(id = Some(id))
      }

      object #{model_name}  {
        implicit val format#{model_name} = Json.format[#{model_name}]
      }

      trait #{model_name}Component  { this: SlickDaoProfile =>
        import profile.simple._

        class #{model_name.pluralize}Table(tag: Tag) extends BaseTable[#{model_name}](tag, "#{model_name.downcase.pluralize}") {
          def id = column[Long]("id", O.PrimaryKey, O.AutoInc)
          #{attrs.map{|x| column(x)}.join("\n")}

          def * = (#{attrs.map{|x| x.split(':').first}.join(',')}, id.?) <> ((#{model_name}.apply _).tupled, #{model_name}.unapply _)
        }

        implicit object #{model_name.pluralize} extends BaseTableQuery[#{model_name}, #{model_name.pluralize}Table](new #{model_name.pluralize}Table(_)) {}
      }
      EOS
    end

    def self.case_class(attr)
      name, type = attr.split(':')
      if type =~ /^Option/
        "#{name}: #{type} = None"
      else
        "#{name}: #{type}"
      end
    end

    def self.column(attr)
      name, type = attr.split(':')
      %Q{def #{name} = column[#{type}]("#{name.underscore}")}
    end
  end
end
