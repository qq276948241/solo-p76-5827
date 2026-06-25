require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module YogaStudio
  class Application < Rails::Application
    config.load_defaults 7.0
    config.api_only = true
    config.active_record.default_timezone = :local
    config.time_zone = 'Beijing'
  end
end
