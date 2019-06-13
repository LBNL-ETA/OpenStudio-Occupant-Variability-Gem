# `openstudio\extension\core` contains core resource files shared across a variety of measures.


The `core` folder located at `lib\openstudio\extension` contains core resource files shared across a variety of measures.  The files should be edited in the OpenStudio-extension-gem, and the rake task (`bundle exec rake openstudio:measures:copy_resources`) should be used to update the measures that depend on them.
Note that this folder is for 'core' functionality; if a measure's requires a new one-off function, this should be developed in place, within the measure's `resources` folder.


