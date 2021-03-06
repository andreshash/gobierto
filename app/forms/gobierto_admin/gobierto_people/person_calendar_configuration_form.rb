module GobiertoAdmin
  module GobiertoPeople
    class PersonCalendarConfigurationForm
      include ActiveModel::Model

      attr_accessor(
        :person_id,
        :ibm_notes_url,
        :clear_google_calendar_configuration,
        :calendars
      )

      def save
        save_calendar_configuration if valid?
      end

      def person_calendar_configuration
        @person_calendar_configuration ||= person_calendar_configuration_class.find_by(person_id: person_id) || person_calendar_configuration_class.new
      end

      def person_id
        @person_id ||= person_calendar_configuration.person_id
      end

      def ibm_notes_url
        @ibm_notes_url ||= if person_calendar_configuration.respond_to?(:endpoint)
                             person_calendar_configuration.endpoint
                           end
      end

      def calendars
        @calendars ||= if person_calendar_configuration.respond_to?(:calendars)
                         person_calendar_configuration.calendars
                       end
      end

      private

      def person_google_calendar_configuration_class
        ::GobiertoPeople::PersonGoogleCalendarConfiguration
      end

      def person_ibm_notes_configuration_class
        ::GobiertoPeople::PersonIbmNotesCalendarConfiguration
      end

      def person
        @person ||= ::GobiertoPeople::Person.find_by(id: person_id)
      end

      def site
        @site ||= person.site
      end

      def person_calendar_configuration_class
        @person_calendar_configuration_class ||= site.calendar_integration.person_calendar_configuration_class
      end

      def clear_google_calendar_configuration?
        person_google_calendar_configuration_class == person_calendar_configuration.class && clear_google_calendar_configuration == "1"
      end

      def clear_ibm_notes_configuration?
        person_ibm_notes_configuration_class == person_calendar_configuration.class && ibm_notes_url.blank?
      end

      def save_calendar_configuration
        @person_calendar_configuration = person_calendar_configuration.tap do |calendar_configuration_attributes|
          calendar_configuration_attributes.person_id = person_id

          if person_calendar_configuration.respond_to?(:calendars)
            calendar_configuration_attributes.calendars = calendars.select { |c| !c.blank? }
          end

          if calendar_configuration_attributes.respond_to?(:endpoint)
            calendar_configuration_attributes.endpoint = ibm_notes_url
          end
        end

        if @person_calendar_configuration.valid?
          if clear_google_calendar_configuration? || clear_ibm_notes_configuration?
            ::GobiertoPeople::ClearImportedPersonEventsJob.perform_later(person)

            @person_calendar_configuration.destroy

            nil
          else
            @person_calendar_configuration.save

            @person_calendar_configuration
          end
        else
          promote_errors(@person_calendar_configuration.errors)

          false
        end
      end

      protected

      def promote_errors(errors_hash)
        errors_hash.each do |attribute, message|
          errors.add(attribute, message)
        end
      end
    end
  end
end
