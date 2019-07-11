module OpenStudio
  module OccupantVariability
    class OccupancyVariabilityApplier

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


      def create_osw(seed_file_dir, weather_file_dir, lod = 1, occ_sch_file_dir = nil)
        # TODO:Add generate DOE prototype model later
        puts '------> Applying occupant variability measures to the OSW...'
        osw = Marshal.load(Marshal.dump(@@osw))
        osw[:seed_file] = seed_file_dir
        osw[:weather_file] = weather_file_dir
        osw[:name] = "Occupancy Variability LOD#{lod.to_s}"
        osw[:description] = 'Occupancy variability at level of detail ' + lod.to_s

        if lod == 1
        elsif lod == 2
          OpenStudio::Extension.set_measure_argument(osw, 'Occupancy_Simulator', '__SKIP__', false)
          if occ_sch_file_dir.nil?
            OpenStudio::Extension.set_measure_argument(osw, 'create_lighting_schedule', '__SKIP__', false)
          else
            OpenStudio::Extension.set_measure_argument(osw, 'create_lighting_schedule', 'occ_schedule_dir', occ_sch_file_dir)
          end
          if occ_sch_file_dir.nil?
            OpenStudio::Extension.set_measure_argument(osw, 'create_mels_schedule_from_occupant_count', '__SKIP__', false)
          else
            OpenStudio::Extension.set_measure_argument(osw, 'create_mels_schedule_from_occupant_count', 'occ_schedule_dir', occ_sch_file_dir)
          end
        elsif lod == 3
          OpenStudio::Extension.set_measure_argument(osw, 'Occupancy_Simulator', '__SKIP__', false)
          OpenStudio::Extension.set_measure_argument(osw, 'create_lighting_schedule', '__SKIP__', false)
          OpenStudio::Extension.set_measure_argument(osw, 'create_mels_schedule_from_occupant_count', '__SKIP__', false)
          OpenStudio::Extension.set_measure_argument(osw, 'add_demand_controlled_ventilation', '__SKIP__', false)
          OpenStudio::Extension.set_measure_argument(osw, 'update_hvac_setpoint_schedule', '__SKIP__', false)
        end

        return osw
      end

    end
  end
end