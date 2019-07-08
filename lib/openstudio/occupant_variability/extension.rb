require 'openstudio/extension'

module OpenStudio
  module OccupantVariability
    class Extension < OpenStudio::Extension::Extension

      # Default file name set by occupancy simulator, change according in the future as needed.
      @@default_occupant_schedule_filename = 'OccSimulator_out_IDF.csv'

      # Override parent class
      def initialize
        super
        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end

      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(@root_dir, 'lib', 'measures'))
      end

      # Relevant files such as weather data, design days, etc.
      # Return the absolute path of the files or nil if there is none, used when configuring OSWs
      def files_dir
        return File.absolute_path(File.join(@root_dir, 'lib', 'files'))
      end

      # Doc templates are common files like copyright files which are used to update measures and other code
      # Doc templates will only be applied to measures in the current repository
      # Return the absolute path of the doc templates dir or nil if there is none
      def doc_templates_dir
        return File.absolute_path(File.join(@root_dir, 'doc_templates'))
      end

      def get_occupancy_schedule_file_name
        @@default_occupant_schedule_filename
      end

      def get_occupancy_schedule_file_dir
        self.files_dir + "/#{self.get_occupancy_schedule_file_name}"
      end

    end
  end
end