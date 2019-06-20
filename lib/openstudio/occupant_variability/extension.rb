require 'openstudio/extension'

module OpenStudio
  module OccupantVariability
    class Extension < OpenStudio::Extension::Extension
      # Override parent class
      def initialize
        super

        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end
    end
  end
end