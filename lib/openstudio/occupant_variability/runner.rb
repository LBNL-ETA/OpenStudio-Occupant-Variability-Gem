# TODO: Create the runner module (refer to the extension gem)


module OpenStudio
  module OccupantVariability
    class Runner

      def init()
      end


      def run_occupancy_simulator(simulation_dir)
        FileUtils.mkdir_p(simulation_dir) if !File.exists?(simulation_dir)


      end

    end

  end
end