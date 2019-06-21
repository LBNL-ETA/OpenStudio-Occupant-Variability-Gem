module OpenStudio
  module OccupantVariability
    class OccupancySimulatorApplier

      # class level variables
      @@instance_lock = Mutex.new
      @@osw = nil

      def initialize(baseline_osw_dir)
        # do initialization of class variables in thread safe way
        @@instance_lock.synchronize do
          if @@osw.nil?

            # load the OSW for this class
            osw_path = File.join(baseline_osw_dir, 'baseline.osw')
            File.open(osw_path, 'r') do |file|
              @@osw = JSON.parse(file.read, symbolize_names: true)
            end

            # add any paths local to the project
            @@osw[:file_paths] << File.join(File.dirname(__FILE__), '../weather/')

            # configures OSW with extension gem paths for measures and files, all extension gems must be
            # required before this
            @@osw = OpenStudio::Extension.configure_osw(@@osw)
          end
        end
      end

      def create_osw(userLib_csv_dir)

        osw = Marshal.load(Marshal.dump(@@osw))

        puts 'Here we are.'

        # puts OpenStudio
        puts OpenStudio::Extension.methods

        # OpenStudio::Extension.set_measure_argument(osw, 'Occupancy_Simulator', '__SKIP__', false)
        # OpenStudio::Extension.set_measure_argument(osw, 'ReduceLightingLoadsByPercentage', '__SKIP__', false)


        puts osw

        return osw
      end

    end
  end
end