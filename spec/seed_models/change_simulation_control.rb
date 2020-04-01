require 'C:/openstudio-2.9.1/Ruby/openstudio.rb'

def loadOSM(pathStr)
  translator = OpenStudio::OSVersion::VersionTranslator.new
  path = OpenStudio::Path.new(pathStr)
  model = translator.loadModel(path)
  if model.empty?
    raise "Input #{pathStr} is not valid, please check."
  else
    model = model.get
  end
  return model
end

def set_simulation_control(model)
    model.getSimulationControl.setRunSimulationforSizingPeriods(false)
    model.getSimulationControl.setRunSimulationforWeatherFileRunPeriods(true)
    return model
end



osm_files = Dir['*.osm']

# osm_files.each do |osm_file|
#     model = loadOSM(osm_file)
#     model = set_simulation_control(model)
#     model.save(osm_file, true)
# end

puts osm_files




