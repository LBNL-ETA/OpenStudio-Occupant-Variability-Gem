module OpenStudio
  module OccupantVariability
    class OccupancySimulatorApplier

      # class level variables
      @@instance_lock = Mutex.new
      @@osw = nil

      def initialize(baseline_osw_dir, files_dir)
        # do initialization of class variables in thread safe way
        @@instance_lock.synchronize do
          if @@osw.nil?

            # load the OSW for this class
            osw_path = File.join(baseline_osw_dir, 'baseline.osw')
            File.open(osw_path, 'r') do |file|
              @@osw = JSON.parse(file.read, symbolize_names: true)
            end

            # add any paths local to the project
            @@osw[:file_paths] << File.join(files_dir)

            # configures OSW with extension gem paths for measures and files, all extension gems must be
            # required before this
            @@osw = OpenStudio::Extension.configure_osw(@@osw)
          end
        end
      end

      def create_osw_lod1(seed_file_dir, weather_file_dir)
        # TODO:Add LOD options later
        puts '~~~ Applying occupant variability measures to the OSW...'
        osw = Marshal.load(Marshal.dump(@@osw))
        osw[:seed_file] = seed_file_dir
        osw[:weather_file] = weather_file_dir
        osw[:name] = 'Occupancy Simulator'
        osw[:description] = 'Occupancy Simulator'

        OpenStudio::Extension.set_measure_argument(osw, 'Occupancy_Simulator', '__SKIP__', false)
        

        return osw
      end

    end
  end
end