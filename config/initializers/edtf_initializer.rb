Edtf::Humanize.configure do |config|
  config.day_precision_strftime_format = "%B %-d, %Y"
  config.month_precision_strftime_format = "%B %Y"
  config.year_precision_strftime_format = "%Y"
  config.approximate_date_prefix = "circa "
  config.uncertain_date_suffix = "?"
  config.decade_suffix = "s"
  config.century_suffix = "s"
  config.unspecified_digit_substitute = "x"
  config.interval_connector = " to "
  config.interval_unspecified_suffix = "s"
  config.set_dates_connector = ", "
  config.set_last_date_connector = " or "
  config.set_two_dates_connector = " or "
  config.unknown = "unknown"
end