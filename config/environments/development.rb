Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.log_level = :debug
  config.logger = ActiveSupport::Logger.new($stdout)
end
