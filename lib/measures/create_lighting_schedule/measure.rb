# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# require 'C:/openstudio-2.7.0/Ruby/openstudio.rb'
# start the measure
class CreateLightingSchedule < OpenStudio::Measure::ModelMeasure

  # Class variables
  @@LPD = 8.5     # Default lighting power density: 8.5 W/m2
  @@F_rad = 0.7   # Default radiation fraction: 0.7
  @@F_vis = 0.2   # Default visible fraction: 0.2
  @@minute_per_item = 10    # 10 minutes per simulation step

  # Standard space types for office rooms
  @@v_office_space_types = [
    'WholeBuilding - Sm Office',
    'WholeBuilding - Md Office',
    'WholeBuilding - Lg Office',
    'Office',
    'ClosedOffice',
    'OpenOffice',
    'SmallOffice - ClosedOffice',
    'SmallOffice - OpenOffice'
  ]
  # Standard space types for meeting rooms
  @@v_conference_space_types = [
    'Conference',
    'SmallOffice - Conference',
  ]
  # Standard space types for auxiliary rooms
  @@v_auxiliary_space_types = [
    'OfficeLarge Data Center',
    'OfficeLarge Main Data Center',
    'SmallOffice - Elec/MechRoom',
  ]
  @@v_other_space_types = [
    'Office Attic', 
    'Attic', 
    'Plenum', 
    'Plenum Space Type',
    'SmallOffice - Corridor',
    'SmallOffice - Lobby',
    'SmallOffice - Attic',
    'SmallOffice - Restroom',
    'SmallOffice - Stair',
    'SmallOffice - Storage',
    ''
  ]

  @@office_type_names =[
    'Open-plan office',
    'Closed office'
  ]

  @@conference_room_type_names = [
    'Conference room',
    'Conference room example'
  ]

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Create Lighting Schedule'
  end

  # human readable description
  def description
    return 'Replace this text with an explanation of what the measure does in terms that can be understood by a general building professional audience (building owners, architects, engineers, contractors, etc.).  This description will be used to create reports aimed at convincing the owner and/or design team to implement the measure in the actual building design.  For this reason, the description may include details about how the measure would be implemented, along with explanations of qualitative benefits associated with the measure.  It is good practice to include citations in the measure if the description is taken from a known source or if specific benefits are listed.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replace this text with an explanation for the energy modeler specifically.  It should explain how the measure is modeled, including any requirements about how the baseline model must be set up, major assumptions, citations of references to applicable modeling resources, etc.  The energy modeler should be able to read this description and understand what changes the measure is making to the model and why these changes are being made.  Because the Modeler Description is written for an expert audience, using common abbreviations for brevity is good practice.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new


    # Space type choices
    space_type_chs = OpenStudio::StringVector.new
    office_space_type_chs = OpenStudio::StringVector.new
    meeting_space_type_chs = OpenStudio::StringVector.new
    other_space_type_chs = OpenStudio::StringVector.new


    @@office_type_names.each do |office_type_name|
      office_space_type_chs << office_type_name
    end

    @@conference_room_type_names.each do |conference_room_type_name|
      meeting_space_type_chs << conference_room_type_name
    end

    other_space_type_chs << "Auxiliary"
    other_space_type_chs << "Lobby"
    other_space_type_chs << "Corridor"
    other_space_type_chs << "Other"
    other_space_type_chs << "Plenum"

    # v_spaces = Array.new()
    # v_spaces = model.getSpaces
    v_space_types = model.getSpaceTypes

    i = 1
    # Loop through all space types, group spaces by their types
    v_space_types.each do |space_type|
      # Loop through all spaces of current space type
      # Puplate the valid options for each space depending on its space type
      if @@v_office_space_types.include? space_type.standardsSpaceType.to_s
        space_type_chs = office_space_type_chs
      elsif @@v_conference_space_types.include? space_type.standardsSpaceType.to_s
        space_type_chs = meeting_space_type_chs
      elsif @@v_other_space_types.include? space_type.standardsSpaceType.to_s
        space_type_chs = other_space_type_chs
      # else
      #   space_type_chs = other_space_type_chs
      end

      v_current_spaces = space_type.spaces
      next if not v_current_spaces.size > 0
      v_current_spaces.each do |current_space|

        arg_temp = OpenStudio::Measure::OSArgument::makeChoiceArgument("Space_#{i}_" + current_space.nameString, space_type_chs, true)
        arg_temp.setDisplayName("Space #{i}: " + current_space.nameString)
        # Conditionally set the default choice for the space
        if(@@v_office_space_types.include? space_type.standardsSpaceType.to_s)
          arg_temp.setDefaultValue("Open-plan office")
        elsif(@@v_conference_space_types.include? space_type.standardsSpaceType.to_s)
          arg_temp.setDefaultValue("Conference room")
        elsif(@@v_auxiliary_space_types.include? space_type.standardsSpaceType.to_s)
          arg_temp.setDefaultValue('Auxiliary')
        elsif(@@v_other_space_types.include? space_type.standardsSpaceType.to_s)
          # If the space type is not in standard space types
          arg_temp.setDefaultValue('Other')
        end
        args << arg_temp
        i += 1
      end
    end

    return args
  end

  def add_light(model, space, schedule, lpd=@@LPD, frac_rad=@@F_rad, frac_vis=@@F_vis)
    # This function creates and adds OS:Light and OS:Light:Definition objects to a space
    space_name = space.name.to_s
    # New light definition
    new_light_def = OpenStudio::Model::LightsDefinition.new(model)
    new_light_def.setDesignLevelCalculationMethod('Watts/Area', 1, 1)
    new_light_def.setName(space_name + ' light definition')
    new_light_def.setWattsperSpaceFloorArea(lpd) # Provide default value, allow users to override
    new_light_def.setFractionRadiant(frac_rad)
    new_light_def.setFractionVisible(frac_vis)
  
    # New light
    new_light = OpenStudio::Model::Lights.new(new_light_def)
    new_light.setName(space_name + ' light')
    new_light.setSpace(space)
    new_light.setSchedule(schedule)
  
    return model
  end

  def create_lighting_sch_from_occupancy_count(space_name, v_timestamps, v_occ_n_count, delay=15)
    # This function creates a lighitng schedule based on the occupant count schedule
    # Delay is in minutes
    # Note: Be careful of the timestep format when updating the function
    v_temp = Array.new
    flag_check = false
    timestamp_leaving = nil
    v_occ_n_count.each_with_index do |value_timestamp, i|
      timestamp_current = DateTime.parse(v_timestamps[i])
      v_temp[i] = 0
      if v_occ_n_count[i].to_f > 0
        v_temp[i] = 1
      end
      # Find the timestamp where occupant count starts to be 0
      if(v_occ_n_count[i].to_f == 0 && v_occ_n_count[i-1].to_f > 0)
        # puts 'start counting... index is: ' + i.to_s 
        timestamp_leaving = DateTime.parse(v_timestamps[i])
        flag_check = true
      end
      # Set the valur of the lighting schedule depending on the delay
      if flag_check
        # puts 'current: ' + timestamp_current.to_s
        # puts 'counting: ' + timestamp_leaving.to_s
        if (timestamp_current - timestamp_leaving) < (delay * 1.0/1440.0)
          flag_check = true
          v_temp[i] = 1
        else
          flag_check = false
          v_temp[i] = 0
        end
      end
    end
    return [space_name] + v_temp
  end

  def vcols_to_csv(v_cols, file_name='sch_light.csv')
    # This function write an array of columns(arrays) into a CSV.
    # The first element of each column array is treated as the header of that column
    # Note: the column arrays in the v_cols should have the same length
    nrows = v_cols[0].length
    CSV.open(file_name, 'wb') do |csv|
      0.upto(nrows-1) do |row|
        v_row = Array.new()
        v_cols.each do |v_col|
          v_row << v_col[row] 
        end
        csv << v_row
      end
    end
  end

  def get_os_schedule_from_csv(model, file_name, schedule_name, col, skip_row=0)
    # This function creates an OS:Schedule:File from a CSV at specified position
    file_name = File.realpath(file_name)
    external_file = OpenStudio::Model::ExternalFile::getExternalFile(model, file_name)
    external_file = external_file.get
    schedule_file = OpenStudio::Model::ScheduleFile.new(external_file, col, skip_row)
    schedule_file.setName(schedule_name)
    return schedule_file
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    runner.registerInfo("Start to create lighting measure from occupant schedule")

    ### get file directories
    model_temp_run_path = Dir.pwd + '/'

    # for use in OpenStudio app
    model_temp_resources_path = File.expand_path("../../..", model_temp_run_path) + '/resources/' # where the occupancy schedule will be saved

    # for use in CLI
    model_temp_resources_path = File.expand_path("../..", model_temp_run_path) # where the occupancy schedule will be saved

    ### Get user selected lighting space assumptions for each space
    v_space_types = model.getSpaceTypes
    i = 1
    lght_space_type_arg_vals = {}
    # Loop through all space types, group spaces by their types
    v_space_types.each do |space_type|
      # Loop through all spaces of current space type
      v_current_spaces = space_type.spaces
      next if not v_current_spaces.size > 0
      v_current_spaces.each do |current_space|
        lght_space_type_val = runner.getStringArgumentValue("Space_#{i}_" + current_space.nameString, user_arguments)
        lght_space_type_arg_vals[current_space.nameString] = lght_space_type_val
        i += 1
      end
    end

    puts lght_space_type_arg_vals


    ### Start creating new lighting schedules based on occupancy schedule

    csv_file = model_temp_resources_path + '/files/OccSimulator_out_IDF.csv' # ! Need to update this CSV filename if it's changed in the occupancy simulator

    # Get the spaces with occupancy count schedule available
    v_spaces_occ_sch = File.readlines(csv_file)[3].split(',') # Room ID is saved in 4th row of the occ_sch file 
    v_headers = Array.new
    v_spaces_occ_sch.each do |space_occ_sch|
      if (!['Room ID', 'S0_Outdoor', 'Outside building'].include? space_occ_sch and !space_occ_sch.strip.empty?)
          v_headers << space_occ_sch
      end
    end
    v_headers = ["Time"] + v_headers

    puts v_headers

    # report initial condition of model
    runner.registerInitialCondition("The building has #{v_headers.length-1} spaces with available occupant schedule file.")

    # Read the occupant count schedule file and clean it
    clean_csv = File.readlines(csv_file).drop(6).join
    csv_table_sch = CSV.parse(clean_csv, headers:true)
    new_csv_table = csv_table_sch.by_col!.delete_if do |column_name, column_values|
      !v_headers.include? column_name
    end

    runner.registerInfo("Successfully read occupant count schedule from CSV file.")
    runner.registerInfo("Creating new lighting schedules...")

    # Create lighting schedule based on the occupant count schedule
    v_cols = Array.new
    v_ts = new_csv_table.by_col!['Time']
    v_headers.each do |header|
      if header != 'Time'
        # space_name = header.partition('_').last
        space_name = header
        # puts space_name
        v_occ_n = new_csv_table.by_col![space_name]
        v_light = create_lighting_sch_from_occupancy_count(space_name, v_ts, v_occ_n, 15)
        v_cols << v_light
      end
    end

    runner.registerInfo("Writing new lighting schedules to CSV file.")
    # Write new lighting schedule file to CSV
    file_name_light_sch = 'sch_light.csv'
    vcols_to_csv(v_cols, file_name_light_sch)
    # Important: copy the output csv from the temp run path, so that the external file object can find the file during run
    # FileUtils.cp(model_temp_run_path + file_name_light_sch, model_temp_resources_path)


    # Add new lighting schedule from the CSV file created
    runner.registerInfo("Adding new OS:Schedule:File objects to the model....")

    runner.registerInfo("Removing old OS:Lights and OS:Lights:Definition for office and conference rooms.")
    # Remove old lights definition objects for office and conference rooms
    v_space_types.each do |space_type|
      space_type.spaces.each do |space|
        selected_space_type = lght_space_type_arg_vals[space.name.to_s]
        if (@@office_type_names.include? selected_space_type) || (@@conference_room_type_names.include? selected_space_type)
          space_type.lights.each do |lght|
            puts 'Remove old lights definition object: ' + lght.lightsDefinition.name.to_s
            lght.lightsDefinition.remove
          end
        end 
      end
    end

    # Remove old lights objects for office and conference rooms
    # Caution: the order of deletion matters
    v_space_types.each do |space_type|
      space_type.spaces.each do |space|
        selected_space_type = lght_space_type_arg_vals[space.name.to_s]
        if (@@office_type_names.include? selected_space_type) || (@@conference_room_type_names.include? selected_space_type)
          space_type.lights.each do |lght|
            puts 'Remove old lights object ' + lght.name.to_s
            lght.remove
          end
        end 
      end
    end

    v_spaces = model.getSpaces
    v_spaces.each do |space|
      # puts space.name.to_s
      v_headers.each_with_index do |s_space_name, i|
        if s_space_name.partition('_').last == space.name.to_s
          col = i
          temp_file_path = model_temp_run_path + file_name_light_sch
          sch_file_name = space.name.to_s + ' lght sch'
          scheduleFile = get_os_schedule_from_csv(model, temp_file_path, sch_file_name, col, skip_row=1)
          scheduleFile.setMinutesperItem(@@minute_per_item.to_s)
          puts scheduleFile
          model = add_light(model, space, scheduleFile)
        end
      end
    end


    # report final condition of model
    runner.registerFinalCondition("Finished creating and adding new lighting schedules for #{v_headers.length-1} spaces.")

    return true
  end
end

# register the measure to be used by the application
CreateLightingSchedule.new.registerWithApplication
