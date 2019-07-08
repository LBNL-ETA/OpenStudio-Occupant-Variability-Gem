module OpenStudio
  module OccupantVariability
    class ModelCreator

      # @param [String] name
      # @param [String] model_type
      # @param [String] model_dir
      # @param [String] vintage
      # @param [String] climate_zone
      def initialize(name, model_type, vintage, climate_zone, model_dir)
        puts "------> Initializing a new ModelCretor instance"
        @name = name.split(' ').collect(&:capitalize).join
        @model_type = model_type
        @model_dir = model_dir
        @vintage = vintage
        @climate_zone = climate_zone
      end

      def generate_prototype_model()
        # Generate a model here
        puts "------> Generate the model using OpenStudio-standards"
        model = OpenStudio::Model::Model.new
        @debug = false
        epw_file = 'Not Applicable'
        prototype_creator = Standard.build("#{@vintage}_#{@model_type}")
        prototype_creator.model_create_prototype_model(@climate_zone,
                                                       epw_file,
                                                       @model_dir,
                                                       @debug,
                                                       model)

        # Set the simulation run period to be weather file period
        model = load_osm("#{@model_dir}/SR1/in.osm")
        model = set_simulation_period(model, true, true)
        model.save("#{@model_dir}/SR1/in.osm", true)
        # Move the model/files to a new dir and cleanup
        puts @model_dir
        FileUtils.cp("#{@model_dir}/SR1/in.osm", "#{@model_dir}/")
        FileUtils.cp("#{@model_dir}/SR1/in.idf", "#{@model_dir}/")
        FileUtils.cp("#{@model_dir}/SR1/in.epw", "#{@model_dir}/")
        File.rename("#{@model_dir}/in.osm", "#{@model_dir}/#{@name}.osm")
        File.rename("#{@model_dir}/in.idf", "#{@model_dir}/#{@name}.idf")
        File.rename("#{@model_dir}/in.epw", "#{@model_dir}/#{@name}.epw")
        # Clean up
        FileUtils.rm_rf("#{@model_dir}/SR1/")
      end

      # @param [string] model_dir
      def load_osm(model_dir)
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(model_dir)
        model = translator.loadModel(path)
        if model.empty?
          raise "Input #{model_dir} is not valid, please check."
        else
          model = model.get
        end
        return model
      end

      # @param [osm] model
      # @param [bool] run_sizing
      # @param [bool] run_weather_period
      def set_simulation_period(model, run_sizing = true, run_weather_period = true)
        model_simulation_control = model.getSimulationControl
        model_simulation_control.setRunSimulationforSizingPeriodsNoFail(run_sizing)
        model_simulation_control.setRunSimulationforWeatherFileRunPeriodsNoFail(run_weather_period)
        return model
      end

    end
  end
end