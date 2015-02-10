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
      if options[:controller] == false
        [:controller, :route].map{ |x| paths.delete(x) }
      end
      paths.map {|k,v| FileUtils.mkdir_p(File.dirname(v)) unless File.exists?(v)}

      if options[:dry_run]
        paths.map do |k,v|
          puts "#{k.capitalize}: #{v}".bold.green, generated[k]
        end
      else
        paths.map do |k,v|
          if File.exists?(v) && k != :route
            STDERR.puts "#{v} already exists and will not be overwritten".red
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

      import play.api.libs.json._
      import play.api.libs.functional.syntax._

      import play.modules.reactivemongo.json.collection.JSONCollection
      import play.autosource.reactivemongo._
      import scala.concurrent.ExecutionContext.Implicits.global
      import play.api.Play.current

      object #{model_name.pluralize} extends ReactiveMongoAutoSourceController[#{model_name}] {
        val coll = db.collection[JSONCollection]("#{model_name.pluralize}")
      }
      EOS
    end

    def self.generate_model(model_name, attrs=[])
      sample =<<-EOS
      package models

      import play.api.libs.json.Json

      case class #{model_name}(
        #{attrs.map{|x| case_class(x)}.join(",\n")}
      )

      object #{model_name} {
        implicit val format#{model_name} = Json.format[#{model_name}]
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
  end
end
