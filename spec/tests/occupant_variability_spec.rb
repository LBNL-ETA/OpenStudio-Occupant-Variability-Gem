# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::OccupantVariability do
  it 'has a version number' do
    expect(OpenStudio::OccupantVariability::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::OccupantVariability::OccupantVariability.new
    expect(File.exist?(instance.measures_dir)).to be true
  end

  it 'should run multiple simulation tests with occupant-variability measures' do
    OpenStudio::Extension::Extension::DO_SIMULATIONS = true

    v_osm_paths = []
    gem_root_path = File.expand_path("../..", Dir.pwd)
    spec_folder_path = File.join(gem_root_path, 'spec')
    run_path = File.join(spec_folder_path, 'test_runs', "run_#{Time.now.strftime("%Y%m%d_%H%M%S")}")

    v_osm_paths << File.join(spec_folder_path, 'seed_models/LargeOfficeDetailed_90.1-2013_5A.osm')
    v_osm_paths << File.join(spec_folder_path, 'seed_models/LargeOffice_90.1-2013_5A.osm')
    v_osm_paths << File.join(spec_folder_path, 'seed_models/MediumOfficeDetailed_90.1-2013_5A.osm')
    v_osm_paths << File.join(spec_folder_path, 'seed_models/MediumOffice_90.1-2013_5A.osm')
    v_osm_paths << File.join(spec_folder_path, 'seed_models/SmallOfficeDetailed_90.1-2013_5A.osm')
    v_osm_paths << File.join(spec_folder_path, 'seed_models/SmallOffice_90.1-2013_5A.osm')

    epw_path = File.join(spec_folder_path, 'seed_models/Chicago_TMY3.epw')
    measures_path = File.join(gem_root_path, 'lib/measures')
    other_example_measures_path = File.join(spec_folder_path, 'seed_models/example_measures')

    # Add your OpenStudio measure directories to the list if you want to use additional measures
    v_measure_paths = [
        measures_path,
        other_example_measures_path
    ]

    v_test_measures = [
        'Occupancy_Simulator_os',
    ]

    hash_test_result = test_individual_measure(v_osm_paths, epw_path, v_measure_paths, run_path, v_test_measures)
    puts '==== Test Summary ==='
    puts hash_test_result
  end

  def test_individual_measure(v_seed_osm_paths, epw_path, v_measure_paths, run_path, v_measure_names, max_n_parallel_run = 3)
    # Get seed model
    unless File.directory?(run_path)
      FileUtils.mkdir_p(run_path)
    end

    v_measure_steps_base = [
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "create_lighting_schedule_from_occupant_count",
                "arguments" => {
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "create_mels_schedule_from_occupant_count",
                "arguments" => {
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "update_hvac_setpoint_schedule",
                "arguments" => {
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "add_demand_controlled_ventilation",
                "arguments" => {
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddOutputVariable",
                "arguments" => {
                    "variable_name" => "Zone Mean Air Temperature",
                    "reporting_frequency" => "timestep",
                    "key_value" => "*"
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddOutputVariable",
                "arguments" => {
                    "variable_name" => "Zone People Occupant Count",
                    "reporting_frequency" => "timestep",
                    "key_value" => "*"
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddOutputVariable",
                "arguments" => {
                    "variable_name" => "Zone Lights Electric Energy",
                    "reporting_frequency" => "timestep",
                    "key_value" => "*"
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddOutputVariable",
                "arguments" => {
                    "variable_name" => "Zone Electric Equipment Electric Energy",
                    "reporting_frequency" => "timestep",
                    "key_value" => "*"
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddOutputVariable",
                "arguments" => {
                    "variable_name" => "Zone Ventilation Mass Flow Rate",
                    "reporting_frequency" => "timestep",
                    "key_value" => "*"
                }
            }
        },
        {
            "measure_type" => "OpenStudio",
            "measure_content" => {
                "measure_dir_name" => "AddMeter",
                "arguments" => {
                    "meter_name" => "Electricity:Facility",
                    "reporting_frequency" => "timestep"
                }
            }
        },
        {
            "measure_type" => "Reporting",
            "measure_content" => {
                "measure_dir_name" => "ExportVariabletoCSV",
                "arguments" => {
                    "variable_name" => "Zone Mean Air Temperature",
                    "reporting_frequency" => "Zone Timestep"
                }
            }
        },
        {
            "measure_type" => "Reporting",
            "measure_content" => {
                "measure_dir_name" => "ExportMetertoCSV",
                "arguments" => {
                    "meter_name" => "Electricity:Facility",
                    "reporting_frequency" => "Zone Timestep"
                }
            }
        },
    ]
    hash_test_result = {}

    v_measure_names.each do |measure_name|
      puts '+ ' * 30
      puts measure_name
      # Test all measures one by one and record the status
      hash_test_result[measure_name] = {}
      measure_type_short = measure_name.split('_')[-1]
      if measure_type_short == 'ep'
        str_measure_type = 'EnergyPlus'
      elsif measure_type_short == 'os'
        str_measure_type = 'OpenStudio'
      end
      hash_measure_temp = {
          "measure_type" => str_measure_type,
          "measure_content" => {
              "measure_dir_name" => measure_name,
              "arguments" => {
              }
          }
      }
      v_measure_steps_temp = v_measure_steps_base.dup
      v_measure_steps_temp = v_measure_steps_temp.insert(0, hash_measure_temp)

      v_measure_steps = order_measures(v_measure_steps_temp)
      v_osws = []
      v_seed_osm_paths.each do |seed_osm_path|
        seed_osm_name = File.basename(seed_osm_path, '.osm')
        out_osw_path = File.join(run_path, measure_name, "run_#{seed_osm_name}/#{seed_osm_name}.osw")
        unless File.directory?(File.dirname(out_osw_path))
          FileUtils.mkdir_p(File.dirname(out_osw_path))
        end
        create_workflow(seed_osm_path, epw_path, v_measure_paths, v_measure_steps, out_osw_path)
        v_osws << out_osw_path
      end

      puts '= ' * 30
      puts "Testing => #{measure_name}"
      puts v_osws

      # Run the workflow
      runner = OpenStudio::Extension::Runner.new(run_path)
      runner.run_osws(v_osws, max_n_parallel_run) # Maximum number of parallel run allowed

      # Summarize the result
      v_osws.each do |osw_path|
        report_file = File.join(File.dirname(osw_path), 'reports', 'eplustbl.html')
        osm_name = File.basename(osw_path, '.osw')
        hash_test_result[measure_name][osm_name] = File.exist?(report_file)
      end
    end

    File.write(File.join(run_path, 'test_result.json'), hash_test_result.to_json)

    hash_test_result
  end

  def create_workflow(seed_osm_path, weather_file_path, measure_paths, v_measure_steps, out_osw_path)
    hash_osw = {
        "seed_file" => seed_osm_path,
        "weather_file" => weather_file_path,
        "measure_paths" => measure_paths,
        "steps" => v_measure_steps
    }
    File.open(out_osw_path, "w") do |f|
      f.write(JSON.pretty_generate(hash_osw))
    end
  end

  def order_measures(v_hash_measure_steps)
    v_measure_os = []
    v_measure_ep = []
    v_measure_rp = []
    v_hash_measure_steps.each do |hash_step_raw|
      if hash_step_raw["measure_type"] == "OpenStudio"
        v_measure_os << hash_step_raw["measure_content"]
      elsif hash_step_raw["measure_type"] == "EnergyPlus"
        v_measure_ep << hash_step_raw["measure_content"]
      elsif hash_step_raw["measure_type"] == "Reporting"
        v_measure_rp << hash_step_raw["measure_content"]
      end
    end
    v_measure_steps_ordered = v_measure_os + v_measure_ep + v_measure_rp
    return v_measure_steps_ordered
  end

end
