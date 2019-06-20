module OpenStudio
  module OccupantVariability
    class ModelCreator

        # @param [String] name
        # @param [String] model_type
        # @param [String] model_dir
        # @param [String] vintage
        # @param [String] climate_zone
        def initialize(name, model_type, vintage, climate_zone, model_dir)
          puts "---> Initializing a new ModelCretor instance"
          @name = name
          @model_type = model_type
          @model_dir = model_dir
          @vintage = vintage
          @climate_zone = climate_zone
        end

        def generate_model()
          # Generate a model here
          puts "---> Generate the model using OpenStudio-standards"
          model = OpenStudio::Model::Model.new
          @debug = false
          epw_file = 'Not Applicable'
          prototype_creator = Standard.build("#{@vintage}_#{@model_type}")
          prototype_creator.model_create_prototype_model(@climate_zone,
                                                         epw_file,
                                                         @model_dir,
                                                         @debug,
                                                         model)
        end

    end
  end
end