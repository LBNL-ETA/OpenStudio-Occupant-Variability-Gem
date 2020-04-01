

###### (Automatically generated documentation)

# System-Level KPIs

## Description
This measure calculate the system-level key performance indicators (KPIs).
The following variables need to be added in order to enable the corresponding KPIs reporting.
Lighting System KPIs:
MELs KPIs:


## Modeler Description
For the most part consumption data comes from the tabular EnergyPlus results, however there are a few requests added for time series results. Space type and loop details come from the OpenStudio model. The code for this is modular, making it easy to use as a template for your own custom reports. The structure of the report uses bootstrap, and the graphs use dimple js.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Which Unit System do you want to use?

**Name:** units,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Lighting System KPIs

**Name:** lighting_kpi_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### MELs System KPIs

**Name:** mels_kpi_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC System KPIs

**Name:** hvac_kpi_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Service Water Heating System KPIs

**Name:** swh_kpi_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Report monthly fuel and enduse breakdown to registerValue
This argument does not effect HTML file, instead it makes data from individal cells of monthly tables avaiable for machine readable values in the resulting OpenStudio Workflow file.
**Name:** reg_monthly_details,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false





## Outputs






























electricity_ip, natural_gas_ip, additional_fuel_ip, district_heating_ip, district_cooling_ip, total_site_eui, eui, net_site_energy, annual_peak_electric_demand, unmet_hours_during_occupied_cooling, unmet_hours_during_occupied_heating, first_year_capital_cost, annual_utility_cost, total_lifecycle_cost


## Contributors
 - Primary development by the commercial buildings team at NREL
 - Support for SI units reporting developed by Julien Marrec with EffiBEM and Julien Thirifays with IGRETEC