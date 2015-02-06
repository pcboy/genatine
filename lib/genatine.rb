require "genatine/version"
require 'active_support/inflector'

module Genatine
  class Genatine
    def self.generate(model_name, attrs=[])
    capitalized = model_name.capitalize

    sample =<<-EOS
    package models

    import slick.dao.{SlickDaoProfile, Entity}                                                                                                                                                                                                                                                                 
    import play.api.libs.json.Json

    case class #{capitalized}(
      #{attrs.map{|x| case_class(x) + ","}.join("\n")}
      id: Option[Long] = None
    ) extends Entity[#{capitalized}] {
      def withId(id: Long): #{capitalized} = copy(id = Some(id))
    }

    object #{capitalized}  {
      implicit val format#{capitalized} = Json.format[#{capitalized}]
    }

    trait #{capitalized}Component  { this: SlickDaoProfile =>
      import profile.simple._

      class #{capitalized.pluralize}Table(tag: Tag) extends BaseTable[#{capitalized}](tag, "#{model_name.downcase.pluralize}") {
        def id = column[Long]("id", O.PrimaryKey, O.AutoInc)
        #{attrs.map{|x| column(x)}.join("\n")}

        def * = (#{attrs.map{|x| x.split(':').first}.join(',')}, id.?) <> ((#{capitalized}.apply _).tupled, #{capitalized}.unapply _)
      }

      implicit object #{capitalized.pluralize} extends BaseTableQuery[#{capitalized}, #{capitalized.pluralize}Table](new #{capitalized.pluralize}Table(_)) {}
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
