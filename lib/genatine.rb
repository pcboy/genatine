require "genatine/version"
require 'active_support/inflector'

module Genatine
  class Genatine
    def self.generate(model_name, attrs=[])
    sample =<<-EOS
    package models

    import slick.dao.{SlickDaoProfile, Entity}                                                                                                                                                                                                                                                                 
    import play.api.libs.json.Json

    case class #{model_name.capitalize}(
      #{attrs.map{|x| case_class(x) + ","}.join("\n")}
      id: Option[Long] = None
    ) extends Entity[#{model_name.capitalize}] {
      def withId(id: Long): #{model_name.capitalize} = copy(id = Some(id))
    }

    object #{model_name.capitalize}  {
      implicit val format#{model_name.capitalize} = Json.format[#{model_name.capitalize}]
    }

    trait #{model_name.capitalize}Component  { this: SlickDaoProfile =>
      import #{model_name.downcase}.simple._

      class #{model_name.capitalize.pluralize}Table(tag: Tag) extends BaseTable[#{model_name.capitalize}](tag, "#{model_name.downcase.pluralize}") {
        def id = column[Long]("id", O.PrimaryKey, O.AutoInc)
        #{attrs.map{|x| column(x)}.join("\n")}

        def * = (#{attrs.map{|x| x.split(':').first}.join(',')}, id.?) <> ((#{model_name.capitalize}.apply _).tupled, #{model_name.capitalize}.unapply _)
      }

      implicit object #{model_name.capitalize.pluralize} extends BaseTableQuery[#{model_name.capitalize}, #{model_name.capitalize.pluralize}Table](new #{model_name.capitalize.pluralize}Table(_)) {}
    }
    EOS
    end

    private

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
