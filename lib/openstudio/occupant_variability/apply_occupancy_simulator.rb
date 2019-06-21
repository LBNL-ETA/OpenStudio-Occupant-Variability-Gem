module OpenStudio
  module OccupantVariability
    class ApplyOccupancySimulator

      # class level variables
      @@osw = nil

      def create_osw(userLib_csv_dir)

        osw = Marshal.load(Marshal.dump(@@osw))

        puts 'Here we are.'

        # OpenStudio::Extension.set_measure_argument(osw, 'ReduceElectricEquipmentLoadsByPercentage', '__SKIP__', false)
        # OpenStudio::Extension.set_measure_argument(osw, 'ReduceLightingLoadsByPercentage', '__SKIP__', false)

        return osw
      end

    end
  end
end