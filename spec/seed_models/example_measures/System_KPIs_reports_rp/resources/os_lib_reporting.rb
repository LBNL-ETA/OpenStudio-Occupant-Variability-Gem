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

require 'json'
require 'openstudio-standards'
require 'yaml'

$J_to_KWH = OpenStudio.convert(1, 'J', 'kWh').get
$WH_to_KWH = OpenStudio.convert(1, 'Wh', 'kWh').get
$W_to_KW = OpenStudio.convert(1, 'W', 'kW').get
$M3S_to_CFM = OpenStudio.convert(1, 'm^3/s', 'cfm').get
$M3S_to_GPM = 15850.32314 # US Liquid volume flow rate conversion
$M3_to_GALLON = 264.172 # US Liquid volume flow rate conversion

module OsLib_Reporting
  # setup - get model, sql, and setup web assets path
  def self.setup(runner)
    results = {}

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # get the last idf
    workspace = runner.lastEnergyPlusWorkspace
    if workspace.empty?
      runner.registerError('Cannot find last idf file.')
      return false
    end
    workspace = workspace.get

    # get the last sql file
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # populate hash to pass to measure
    results[:model] = model
    # results[:workspace] = workspace
    results[:sqlFile] = sqlFile

    return results
  end

  def self.ann_env_pd(sqlFile)
    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
        end
      end
    end

    return ann_env_pd
  end

  def self.create_xls
    require 'rubyXL'
    book = ::RubyXL::Workbook.new

    # delete initial worksheet

    return book
  end

  def self.save_xls(book)
    file = book.write 'excel-file.xlsx'

    return file
  end

  # write an Excel file from table data
  # the Excel Functions are not currently being used, left in as example
  # Requires ruby Gem which isn't currently supported in OpenStudio GUIs.
  # Current setup is simple, creates new workbook for each table
  # Could be updated to have one section per workbook
  def self.write_xls(table_data, book)
    worksheet = book.add_worksheet table_data[:title]

    row_cnt = 0
    # write the header row
    header = table_data[:header]
    header.each_with_index do |h, i|
      worksheet.add_cell(row_cnt, i, h)
    end
    worksheet.change_row_fill(row_cnt, '0ba53d')

    # loop over data rows
    data = table_data[:data]
    data.each do |d|
      row_cnt += 1
      d.each_with_index do |c, i|
        worksheet.add_cell(row_cnt, i, c)
      end
    end

    return book
  end

  # cleanup - prep html and close sql
  def self.cleanup(html_in_path)
    # TODO: - would like to move code here, but couldn't get it working. May look at it again later on.

    return html_out_path
  end

  # clean up unkown strings used for runner.registerValue names
  def self.reg_val_string_prep(string)
    # replace non alpha-numberic characters with an underscore
    string = string.gsub(/[^0-9a-z]/i, '_')

    # snake case string
    string = OpenStudio.toUnderscoreCase(string)

    return string
  end

  ###########################################################
  # Utility functions
  ###########################################################
  def self.get_ts_by_var_key(runner, sqlFile, var_k_name, freq = 'Zone Timestep')
    hash_result = {}
    ann_env_pd = OsLib_Reporting.ann_env_pd(sqlFile)
    runner.registerInfo("= = =>Getting #{var_k_name} timeseries at #{freq} frequency from #{ann_env_pd}")
    if ann_env_pd
      runner.registerInfo("We are here!!!")
      keys = sqlFile.availableKeyValues(ann_env_pd, freq, var_k_name)
      runner.registerInfo("Key length is #{keys.length}")
      keys.each do |key|
        runner.registerInfo("SWH key = #{key}")
        output_timeseries = sqlFile.timeSeries(ann_env_pd, freq, var_k_name, key)
        if output_timeseries.is_initialized
          output_timeseries = output_timeseries.get.values
        else
          runner.registerWarning("Didn't find data for #{var_k_name}")
        end
        v_temp = []
        for i in 0..(output_timeseries.size - 1)
          v_temp << output_timeseries[i]
        end
        hash_result[key] = v_temp
      end
    end
    return hash_result
  end

  def self.get_zone_area(model, runner)
    source_units_area = "m^2"
    target_units_area = "ft^2"
    target_units_area = "m^2"

    # Space area
    hash_zone_area = {}
    spaces = model.getSpaces
    spaces.each do |space|
      area = OpenStudio.convert(space.floorArea, source_units_area, target_units_area).get
      key = space.thermalZone.get.name.to_s.upcase
      hash_zone_area[key] = area
      runner.registerInfo("Space = #{space.thermalZone.get.name}, Area = #{hash_zone_area[key]}")
    end
    hash_zone_area
  end

  def self.arr_sum(v_val)
    v_val.inject(0) { |sum, i| sum + i.to_f }
  end

  def self.hash_sum(hash_k_arr)
    # This method sum all the array values for a hash of key:array
    OsLib_Reporting.arr_sum(hash_k_arr.map { |k, v| OsLib_Reporting.arr_sum(v) })
  end


  def self.get_true_zone_name(key, hash_ts)
    true_key = key
    hash_ts.each do |hash_key, ts|
      if hash_key.include? key
        true_key = hash_key
      end
    end
    return true_key
  end

  def self.get_degree_days(model, hdd_base = 18, cdd_base = 10)
    weather_file = model.getWeatherFile.file
    weather_file = weather_file.get
    data = weather_file.data
    cdd = 0.0 # degreeDays
    hdd = 0.0 # degreeDays
    data.each do |epw_data_point|
      temperature = epw_data_point.dryBulbTemperature.get # degreeCelsius
      cdd += [temperature - cdd_base, 0].max / 24 # degreeDays
      hdd += [hdd_base - temperature, 0].max / 24 # degreeDays
    end
    return [hdd, cdd]
  end

  def self.get_non_zero_avg_2ts(arr_ts_1, arr_ts_2, conversion_ts_1 = 1, conversion_ts_2 = 1)
    # two arrays should have the same length
    val_sum = 0
    count = 0
    arr_ts_1.each_with_index do |val, i|
      unless val == 0
        count += 1
        val_sum += (val * conversion_ts_1).to_f / (arr_ts_2[i] * conversion_ts_2)
      end
    end
    val_sum / count
  end

  ##############################################################################
  # create lighting_kpi_section
  def self.lighting_kpi_section(model, sqlFile, runner, name_only = false, is_ip_units = true)
    # Initial setup
    lighting_system_kpi_tables = []
    @lighting_system_kpi_section = {}
    @lighting_system_kpi_section[:title] = 'Lighting System KPIs'
    @lighting_system_kpi_section[:tables] = lighting_system_kpi_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only
      return @lighting_system_kpi_section
    end

    ############################################################################
    # Get raw space information and timeseries results
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f

    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Zone Lights Electric Energy'
    hash_elec_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone Lights Electric Power'
    hash_elec_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone People Occupant Count'
    hash_occ_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    ############################################################################
    # Non-occupant related KPIs

    runner.registerInfo("Testing " * 30)

    runner.registerInfo("---> Calculating non-occupant-related lighting system KPIs.")
    lighting_system_kpi_table_01 = {}
    lighting_system_kpi_table_01[:title] = 'Non-occupant-related Lighting System KPIs'
    lighting_system_kpi_table_01[:header] = ['Zone',
                                             'Annual Electricity Consumption',
                                             'Annual Electricity Use Intensity',
                                             'Peak Power Density']
    lighting_system_kpi_table_01[:units] = ['',
                                            'kWh',
                                            'kWh/m^2',
                                            'W/m^2']
    lighting_system_kpi_table_01[:data] = []
    hash_zone_area.each do |key, area|
      begin
        j_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_j_ts)
        w_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_w_ts)
        lighting_system_kpi_table_01[:data] << [key,
                                                (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH).to_i,
                                                (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / area).to_i,
                                                (hash_elec_w_ts[w_key].max / area).round(1)]
      rescue
        runner.registerInfo("No lighting electricity consumption time series data found for #{key}.")
      end
    end

    ############################################################################
    # Occupant related KPIs
    runner.registerInfo("---> Calculating occupant-related lighting system KPIs.")
    lighting_system_kpi_table_02 = {}
    lighting_system_kpi_table_02[:title] = 'Occupant-related Lighting System KPIs'
    lighting_system_kpi_table_02[:header] = ['Zone',
                                             'Annual Lighting Electricity Consumption Per Person',
                                             'Annual Lighting Electricity Consumption per Occupied Hours',
                                             'Peak Electric Power Per Max Occupants']
    lighting_system_kpi_table_02[:units] = ['',
                                            'kWh/(max occupants)',
                                            'kWh/(FTE occupied hour)',
                                            'W/(max occupants)']
    lighting_system_kpi_table_02[:data] = []

    hash_zone_area.each do |key, area|
      begin
        j_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_j_ts)
        w_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_w_ts)
        o_key = OsLib_Reporting.get_true_zone_name(key, hash_occ_ts)
        v_temp = [key,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / hash_occ_ts[o_key].max).to_i,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / OsLib_Reporting.arr_sum(hash_occ_ts[o_key]) / s_per_h).round(3),
                  (hash_elec_w_ts[w_key].max / hash_occ_ts[o_key].max).round(1)]
        lighting_system_kpi_table_02[:data] << v_temp
      rescue
        runner.registerInfo("No lighting electricity consumption time series data found for #{key}.")
      end
    end

    ############################################################################
    # add table to array of tables
    lighting_system_kpi_tables << lighting_system_kpi_table_01
    lighting_system_kpi_tables << lighting_system_kpi_table_02

    return @lighting_system_kpi_section
  end

  ##############################################################################
  # create lighting_kpi_section
  def self.mels_kpi_section(model, sqlFile, runner, name_only = false, is_ip_units = true)
    # Initial setup
    mels_system_kpi_tables = []
    @mels_system_kpi_section = {}
    @mels_system_kpi_section[:title] = 'MELs System KPIs'
    @mels_system_kpi_section[:tables] = mels_system_kpi_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only
      return @mels_system_kpi_section
    end

    ############################################################################
    # Get raw space information and timeseries results
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Electric Equipment Electric Energy'
    hash_elec_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Electric Equipment Electric Power'
    hash_elec_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone People Occupant Count'
    hash_occ_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    ############################################################################
    # Non-occupant related KPIs
    runner.registerInfo("---> Calculating non-occupant-related mels system KPIs.")
    mels_system_kpi_table_01 = {}
    mels_system_kpi_table_01[:title] = 'Non-occupant-related mels System KPIs'
    mels_system_kpi_table_01[:header] = ['Zone',
                                         'Annual Electricity Consumption',
                                         'Annual Electricity Use Intensity',
                                         'Peak Power Density']
    mels_system_kpi_table_01[:units] = ['',
                                        'kWh',
                                        'kWh/m^2',
                                        'W/m^2']
    mels_system_kpi_table_01[:data] = []
    hash_zone_area.each do |key, area|
      j_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_j_ts)
      w_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_w_ts)
      begin
        mels_system_kpi_table_01[:data] << [key,
                                            (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH).to_i,
                                            (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / area).to_i,
                                            (hash_elec_w_ts[w_key].max / area).round(1)]
      rescue
        runner.registerInfo("No mels electricity consumption time series data found for #{key}.")
      end
    end

    ############################################################################
    # Occupant related KPIs
    runner.registerInfo("-" * 50)
    runner.registerInfo("---> Calculating occupant-related mels system KPIs.")
    mels_system_kpi_table_02 = {}
    mels_system_kpi_table_02[:title] = 'Occupant-related mels System KPIs'
    mels_system_kpi_table_02[:header] = ['Zone',
                                         'Annual MELs Electricity Consumption Per Max Occupants',
                                         'Annual MELs Electricity Consumption Per Occupied Hour',
                                         'Peak Electric Power Per Max Occupants']
    mels_system_kpi_table_02[:units] = ['',
                                        'kWh/(max occupants)',
                                        'kWh/(FTE occupied hour)',
                                        'W/(max occupants)']
    mels_system_kpi_table_02[:data] = []

    hash_zone_area.each do |key, area|
      begin
        j_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_j_ts)
        w_key = OsLib_Reporting.get_true_zone_name(key, hash_elec_w_ts)
        o_key = OsLib_Reporting.get_true_zone_name(key, hash_occ_ts)
        v_temp = [key,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / hash_occ_ts[o_key].max).to_i,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / OsLib_Reporting.arr_sum(hash_occ_ts[o_key]) / s_per_h).round(3),
                  (hash_elec_w_ts[w_key].max / hash_occ_ts[o_key].max).round(1)]
        mels_system_kpi_table_02[:data] << v_temp
      rescue
        runner.registerInfo("No mels electricity consumption time series data found for #{key}.")
      end
    end

    ############################################################################
    # add table to array of tables
    mels_system_kpi_tables << mels_system_kpi_table_01
    mels_system_kpi_tables << mels_system_kpi_table_02

    return @mels_system_kpi_section
  end


  # create hvac_kpi section
  def self.hvac_kpi_section(model, sqlFile, runner, name_only = false, is_ip_units = true)
    # array to hold tables
    hvac_kpi_tables = []

    # gather data for section
    @hvac_kpi_section = {}
    @hvac_kpi_section[:title] = 'HVAC System KPIs'
    @hvac_kpi_section[:tables] = hvac_kpi_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @hvac_kpi_section
    end

    ###########################################################################
    # Get the total end uses for each fuel type
    bldg_area = model.getBuilding.floorArea

    runner.registerInfo("= " * 50)
    runner.registerInfo("Building area = #{bldg_area}")

    arr_hvac_end_use_categories = ['Heating', 'Cooling', 'Fans', 'Pumps', 'HeatRejection', 'Humidifier', 'HeatRecovery']
    hash_fuel_type_map = {
        '0' => 'Electricity',
        '1' => 'Gas',
        '2' => 'OtherFuel',
        '3' => 'DistrictCooling',
        '4' => 'DistrictHeating',
        '5' => 'Water',
    }
    hash_end_use_consumption = {}
    hash_end_use_power = {}
    # Get end use consumption and peak demand for hvac system
    OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
      fuel_type_str = hash_fuel_type_map[fuel_type.to_s]
      hash_end_use_consumption[fuel_type_str] = {}
      hash_end_use_power[fuel_type_str] = {}

      # Loop through all end use categories
      arr_hvac_end_use_categories.each do |category|
        hash_end_use_consumption[fuel_type_str][category] = 0
        hash_end_use_power[fuel_type_str][category] = 0

        # Loop through months
        OpenStudio::MonthOfYear.getValues.each do |month|
          # Get energy consumption
          if month >= 1 && month <= 12
            if !sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                 OpenStudio::EndUseCategoryType.new(category),
                                                 OpenStudio::MonthOfYear.new(month)).empty?

              category_j = sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                            OpenStudio::EndUseCategoryType.new(category),
                                                            OpenStudio::MonthOfYear.new(month)).get
            else
              category_j = 0
            end
            hash_end_use_consumption[fuel_type_str][category] += category_j # Get sum

            # Get peak demand
            if !sqlFile.peakEnergyDemandByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                OpenStudio::EndUseCategoryType.new(category),
                                                OpenStudio::MonthOfYear.new(month)).empty?

              category_w = sqlFile.peakEnergyDemandByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                           OpenStudio::EndUseCategoryType.new(category),
                                                           OpenStudio::MonthOfYear.new(month)).get
            else
              category_w = 0
            end
            hash_end_use_power[fuel_type_str][category] = [hash_end_use_power[fuel_type_str][category], category_w].max # Get max

          end
        end
      end
    end
    #File.write('G:/DOE_SDI/temp/hash_enduse_power.yml', hash_end_use_power.to_yaml)
    ###########################################################################

    # create table
    hvac_kpi_table_01 = {}
    hvac_kpi_table_01[:title] = 'HVAC Overall'
    hvac_kpi_table_01[:header] = ['Annual HVAC Electricity Energy Use Intensity',
                                  'Annual HVAC Natural Gas Energy Use Intensity',
                                  'Peak HVAC Electricity Demand Intensity',
                                  'Peak HVAC Natural Gas Demand Intensity']
    hvac_kpi_table_01[:units] = ['kWh/m^2', 'kWh/m^2', 'W/m^2', 'W/m^2']
    hvac_kpi_table_01[:data] = []

    annual_electricity_j = hash_end_use_consumption['Electricity'].values.inject { |a, b| a + b }
    annual_fossil_fuel_j = hash_end_use_consumption['Gas'].values.inject { |a, b| a + b }
    annual_electricity_kWh = OpenStudio.convert(annual_electricity_j, 'J', 'kWh').get
    annual_natural_gas_kWh = OpenStudio.convert(annual_fossil_fuel_j, 'J', 'kWh').get
    annual_electricity_kWh_per_m2 = annual_electricity_kWh / bldg_area
    annual_natural_gas_kWh_per_m2 = annual_natural_gas_kWh / bldg_area

    #File.write('G:/DOE_SDI/temp/hash_enduse_consumption.yml', hash_end_use_consumption.to_yaml)


    runner.registerInfo("--- " * 30)
    runner.registerInfo("#{annual_electricity_j}")
    runner.registerInfo("#{annual_fossil_fuel_j}")

    peak_electricity_w = hash_end_use_power['Electricity'].max_by { |k, v| v }[1]
    peak_natural_gas_w = hash_end_use_power['Gas'].max_by { |k, v| v }[1]
    peak_electricity_W_per_m2 = peak_electricity_w / bldg_area
    peak_natural_gas_W_per_m2 = peak_natural_gas_w / bldg_area

    hvac_kpi_table_01[:data] << [annual_electricity_kWh_per_m2.round(1),
                                 annual_natural_gas_kWh_per_m2.round(1),
                                 peak_electricity_W_per_m2.round(1),
                                 peak_natural_gas_W_per_m2.round(1)]


    # add table to array of tables
    hvac_kpi_tables << hvac_kpi_table_01
    hvac_kpi_tables << OsLib_Reporting.hvac_heating_KPI_table(model, sqlFile, runner, hash_end_use_consumption, hash_end_use_power, is_ip_units = true)
    hvac_kpi_tables << OsLib_Reporting.hvac_cooling_KPI_table(model, sqlFile, runner, hash_end_use_consumption, hash_end_use_power, is_ip_units = true)
    hvac_kpi_tables << OsLib_Reporting.hvac_ventilation_KPI_table(model, sqlFile, runner, is_ip_units = true)

    # using helper method that generates table for second example
    return @hvac_kpi_section
  end

  def self.hvac_heating_KPI_table(model, sqlFile, runner, hash_end_use_energy, hash_end_use_power, is_ip_units = true)
    # 1. create table structure
    heating_sub_table = {}
    heating_sub_table[:title] = 'Heating Sub-system KPIs'
    heating_sub_table[:header] = ['Heating System Energy Use Intensity',
                                  'Heating System Energy Use Intensity Normalized by Heating Degree Days',
                                  'Heating System Total Efficiency',
                                  'Peak Heating Electricity Demand',
                                  'Peak Heating Electricity Demand Intensity',]

    heating_sub_table[:units] = ['kWh/m^2', 'kWh/(m^2 * HDD18C)', 'kWh Load/kWh Consumption', 'kW', 'W/m^2']
    heating_sub_table[:data] = []

    # 2. Calculate energy related KPIs
    freq = 'Zone Timestep'
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Zone Air System Sensible Heating Energy'
    hash_zone_sensible_heating_load_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    total_space_heating_demand = OsLib_Reporting.hash_sum(hash_zone_sensible_heating_load_ts)
    hdd18c = OsLib_Reporting.get_degree_days(model, hdd_base = 18, cdd_base = 10)[0]

    all_heating_use_j = 0
    hash_end_use_energy.each do |fuel, hash_fuel_use|
      hash_fuel_use.each do |category, val|
        if category == 'Heating'
          all_heating_use_j += val
        end
      end
    end
    all_heating_use_kwh = OpenStudio.convert(all_heating_use_j, 'J', 'kWh').get
    bldg_area = model.getBuilding.floorArea
    heating_eui_kwh_per_m2 = all_heating_use_kwh / bldg_area
    heating_eui_kwh_per_m2_per_hdd = all_heating_use_kwh / (bldg_area * hdd18c)
    heating_sys_demand_efficiency = total_space_heating_demand / all_heating_use_j

    # 3. Calculate power related KPIs
    peak_heating_electricity_w = hash_end_use_power['Electricity']['Heating']
    peak_heating_electricity_kw = OpenStudio.convert(peak_heating_electricity_w, 'W', 'kW').get
    peak_heating_electricity_w_per_m2 = peak_heating_electricity_w / bldg_area

    # Add calculated KPI values to the table
    heating_sub_table[:data] << [heating_eui_kwh_per_m2.round(1),
                                 heating_eui_kwh_per_m2_per_hdd.round(5),
                                 heating_sys_demand_efficiency.round(2),
                                 peak_heating_electricity_kw.round(1),
                                 peak_heating_electricity_w_per_m2.round(1)]
    #File.write('G:/DOE_SDI/temp/hash_zone_areas.yml', hash_zone_area.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_zone_sensible_heating_load_ts.yml', hash_zone_sensible_heating_load_ts.to_yaml)

    return heating_sub_table
  end

  def self.hvac_cooling_KPI_table(model, sqlFile, runner, hash_end_use_energy, hash_end_use_power, is_ip_units = true)
    # 1. create table structure
    cooling_sub_table = {}
    cooling_sub_table[:title] = 'Cooling Sub-system KPIs'
    cooling_sub_table[:header] = ['Cooling System Energy Use Intensity',
                                  'Cooling System Energy Use Intensity Normalized by Cooling Degree Days',
                                  'Cooling System Total Efficiency',
                                  'Peak Cooling Electricity Demand',
                                  'Peak Cooling Electricity Demand Intensity',]

    cooling_sub_table[:units] = ['kWh/m^2', 'kWh/(m^2 * CDD10C)', 'kWh Load/kWh Consumption', 'kW', 'W/m^2']
    cooling_sub_table[:data] = []

    # 2. Calculate energy related KPIs
    freq = 'Zone Timestep'
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Zone Air System Sensible Cooling Energy'
    hash_zone_sensible_cooling_load_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    total_space_cooling_demand = OsLib_Reporting.hash_sum(hash_zone_sensible_cooling_load_ts)
    cdd10c = OsLib_Reporting.get_degree_days(model, hdd_base = 18, cdd_base = 10)[1]

    all_cooling_use_j = 0
    hash_end_use_energy.each do |fuel, hash_fuel_use|
      hash_fuel_use.each do |category, val|
        if category == 'Cooling'
          all_cooling_use_j += val
        end
      end
    end

    all_cooling_use_kwh = OpenStudio.convert(all_cooling_use_j, 'J', 'kWh').get
    bldg_area = model.getBuilding.floorArea
    cooling_eui_kwh_per_m2 = all_cooling_use_kwh / bldg_area
    cooling_eui_kwh_per_m2_per_hdd = all_cooling_use_kwh / (bldg_area * cdd10c)
    cooling_sys_demand_efficiency = total_space_cooling_demand / all_cooling_use_j

    # 3. Calculate power related KPIs
    peak_cooling_electricity_w = hash_end_use_power['Electricity']['Cooling']
    peak_cooling_electricity_kw = OpenStudio.convert(peak_cooling_electricity_w, 'W', 'kW').get
    peak_cooling_electricity_w_per_m2 = peak_cooling_electricity_w / bldg_area

    cooling_sub_table[:data] << [cooling_eui_kwh_per_m2.round(1),
                                 cooling_eui_kwh_per_m2_per_hdd.round(5),
                                 cooling_sys_demand_efficiency.round(2),
                                 peak_cooling_electricity_kw.round(1),
                                 peak_cooling_electricity_w_per_m2.round(1)]
    #File.write('G:/DOE_SDI/temp/hash_zone_areas.yml', hash_zone_area.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_zone_sensible_cooling_load_ts.yml', hash_zone_sensible_cooling_load_ts.to_yaml)

    return cooling_sub_table
  end

  def self.hvac_ventilation_KPI_table(model, sqlFile, runner, is_ip_units = true)
    # 1. create table structure
    ventilation_sub_table = {}
    ventilation_sub_table[:title] = 'Ventilation Sub-system KPIs'
    ventilation_sub_table[:header] = ['Zone',
                                      'Annual ventilation volume per area',
                                      'Average ventilation volume per person hour',
                                      'Average electric power to ventilation rate ratio',
                                      'Average CO2 indoor and outdoor concentration difference during occupied hours'
    ]
    ventilation_sub_table[:units] = ['', 'm^3/m^2', 'm^3/(FTE occupied hour)', 'W/cfm', 'ppm']
    ventilation_sub_table[:data] = []


    # 2. Get mechanical ventilation data
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Zone Mechanical Ventilation Standard Density Volume'
    hash_zone_ventilation_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone People Occupant Count'
    hash_occ_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone Mechanical Ventilation Standard Density Volume Flow Rate'
    hash_zone_ventilation_m3s_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Fan Electric Power'
    hash_fan_electric_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone Air CO2 Concentration'
    hash_zone_co2_ppm_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    ref_co2_ppm = 400


    #File.write('G:/DOE_SDI/temp/hash_zone_ventilation_v_ts.yml', hash_zone_ventilation_v_ts.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_occ_ts.yml', hash_occ_ts.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_zone_ventilation_m3s_ts.yml', hash_zone_ventilation_m3s_ts.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_fan_electric_w_ts.yml', hash_fan_electric_w_ts.to_yaml)


    hash_zone_area.each do |zone, area|
      begin
        ventilation_zone_name = OsLib_Reporting.get_true_zone_name(zone, hash_zone_ventilation_v_ts)
        occ_zone_name = OsLib_Reporting.get_true_zone_name(zone, hash_zone_ventilation_v_ts)
        fan_zone_name = OsLib_Reporting.get_true_zone_name(zone, hash_fan_electric_w_ts)

        row_data = [
            zone,
            (OsLib_Reporting.arr_sum(hash_zone_ventilation_v_ts[ventilation_zone_name]) / area).round(1),
            (OsLib_Reporting.arr_sum(hash_zone_ventilation_v_ts[ventilation_zone_name]) / (OsLib_Reporting.arr_sum(hash_occ_ts[occ_zone_name]) / s_per_h)).round(1),
            (OsLib_Reporting.get_non_zero_avg_2ts(hash_fan_electric_w_ts[fan_zone_name], hash_zone_ventilation_m3s_ts[ventilation_zone_name],
                                                  1, $M3S_to_CFM)).round(1),
            (hash_zone_co2_ppm_ts.length > 0 ? ref_co2_ppm : 'N.A.') #TODO: calculate average CO2 concentration difference
        ]
        ventilation_sub_table[:data] << row_data
      rescue
        runner.registerInfo("No ventilation time series data found for #{zone}.")
      end
    end

    # add rows to table
    return ventilation_sub_table
  end

  # create swh_kpi section
  def self.swh_kpi_section(model, sqlFile, runner, name_only = false, is_ip_units = true)
    # array to hold tables
    swh_kpi_tables = []

    # gather data for section
    @swh_kpi_section = {}
    @swh_kpi_section[:title] = 'Service Water Heating System KPIs'
    @swh_kpi_section[:tables] = swh_kpi_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @swh_kpi_section
    end

    # 1. create table structure
    swh_kpi_table_01 = {}
    swh_kpi_table_01[:title] = 'Service Water Heating System KPIs'
    swh_kpi_table_01[:header] = ['Annual Water Heating Electricity Energy per Occupied Hour',
                                 'Annual Water Heating Gas Energy per Occupied Hour',
                                 'Annual Hot Water Volume per floor area',
                                 'Annual Hot Water Volume per Occupied Hour']
    swh_kpi_table_01[:units] = ['kWh/(FTE occupied hour)', 'kWh/(FTE occupied hour)', 'gallon/m^2', 'gallon/(FTE occupied hour)']
    swh_kpi_table_01[:data] = []

    # 2. get time series data from simulation results
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    bldg_area = model.getBuilding.floorArea

    var_k_name = 'Zone People Occupant Count'
    hash_occ_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)


    var_k_name = 'Water Heater Electricity Energy'
    hash_water_heater_elec_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq) ### OpenStudio cannot find this output variable

    var_k_name = 'Water Heater Electric Power'
    hash_water_heater_elec_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Water Heater Gas Energy'
    hash_water_heater_gas_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Water Heater Water Volume'
    hash_water_heater_v_m3_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq) ### OpenStudio cannot find this output variable

    var_k_name = 'Water Heater Water Volume Flow Rate'
    hash_water_heater_v_m3s_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)


    var_k_name = 'Water Heater Source Side Mass Flow Rate'
    hash_water_heater_src_kgs_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    total_occupied_fte_hours = OsLib_Reporting.hash_sum(hash_occ_ts) / s_per_h
    total_swh_ele_kwh = OsLib_Reporting.hash_sum(hash_water_heater_elec_w_ts) / s_per_h * $WH_to_KWH
    total_swh_gas_kwh = OsLib_Reporting.hash_sum(hash_water_heater_gas_j_ts) * $J_to_KWH
    total_swh_gallon = OsLib_Reporting.hash_sum(hash_water_heater_v_m3s_ts) / s_per_h * $M3_to_GALLON


    #File.write('G:/DOE_SDI/temp/hash_water_heater_v_m3_ts.yml', hash_water_heater_v_m3_ts.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_water_heater_v_m3s_ts.yml', hash_water_heater_v_m3s_ts.to_yaml)
    #File.write('G:/DOE_SDI/temp/hash_water_heater_src_kgs_ts.yml', hash_water_heater_src_kgs_ts.to_yaml)


    runner.registerInfo("total_occupied_fte_hours is #{total_occupied_fte_hours}")
    runner.registerInfo("total_swh_ele_kwh is #{total_swh_ele_kwh}")
    runner.registerInfo("total_swh_gas_kwh is #{total_swh_gas_kwh}")
    runner.registerInfo("total_swh_gallon is #{total_swh_gallon}")

    begin
      swh_kpi_table_01[:data] << [
          (total_swh_ele_kwh / total_occupied_fte_hours).round(3),
          (total_swh_gas_kwh / total_occupied_fte_hours).round(3),
          total_swh_gallon / bldg_area,
          total_swh_gallon / total_occupied_fte_hours]
    rescue
      runner.registerInfo("No water heater result found, please check your output variables.")
    end

    swh_kpi_tables << swh_kpi_table_01
    return @swh_kpi_section
  end

  ##############################################################################
  # create template section
  def self.template_section(model, sqlFile, runner, name_only = false, is_ip_units = true)
    # array to hold tables
    template_tables = []

    # gather data for section
    @template_section = {}
    @template_section[:title] = 'Tasty Treats'
    @template_section[:tables] = template_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @template_section
    end

    # notes:
    # The data below would typically come from the model or simulation results
    # You can loop through objects to make a table for each item of that type, such as air loops
    # If a section will only have one table you can leave the table title blank and just rely on the section title
    # these will be updated later to support graphs

    # create table
    template_table_01 = {}
    template_table_01[:title] = 'Fruit'
    template_table_01[:header] = ['Definition', 'Value']
    template_table_01[:units] = ['', '$/pound']
    template_table_01[:data] = []

    # add rows to table
    template_table_01[:data] << ['Banana', 0.23]
    template_table_01[:data] << ['Apple', 0.75]
    template_table_01[:data] << ['Orange', 0.50]

    # add table to array of tables
    template_tables << template_table_01

    # using helper method that generates table for second example
    template_tables << OsLib_Reporting.template_table(model, sqlFile, runner, is_ip_units = true)

    return @template_section
  end

  # create template section
  def self.template_table(model, sqlFile, runner, is_ip_units = true)
    # create a second table
    template_table = {}
    template_table[:title] = 'Ice Cream'
    template_table[:header] = ['Definition', 'Base Flavor', 'Toppings', 'Value']
    template_table[:units] = ['', '', '', 'scoop']
    template_table[:data] = []

    # add rows to table
    template_table[:data] << ['Vanilla', 'Vanilla', 'NA', 1.5]
    template_table[:data] << ['Rocky Road', 'Chocolate', 'Nuts', 1.5]
    template_table[:data] << ['Mint Chip', 'Mint', 'Chocolate Chips', 1.5]

    return template_table
  end


end
