

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
        @name = name.split(' ').collect(&:capitalize).join
        @model_type = model_type
        @model_dir = model_dir
        @vintage = vintage
        @climate_zone = climate_zone
      end

      def generate_prototype_model()
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
        # Cleanup the model
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

    end
  end
end