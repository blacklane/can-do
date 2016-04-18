require "singleton"
require "yaml"

# Flips your features based on a config/features.yml file or environment variables.
# Environment variables always take precedence over the settings in your YAML file.
#
# @example config/features.yml
#   defaults:
#     some_feature: false
#     other_feature: true
#   development:
#     some_feature: true
#
# @example test if a feature should be enabled
#   > RAILS_ENV=development rails console
#   CanDo.feature?(:some_feature) # => false
#
# @example overwrite setting with environment variable
#   > SOME_FEATURE=true RAILS_ENV=development rails console
#   CanDo.feature?(:some_feature) # => true
#
# @example call with a block
#   CanDo.feature?(:some_feature) do
#     # this block get's called if some_feature is enabled
#   end
#
class CanDo
  include Singleton

  NotAFeature = Class.new(StandardError)

  THE_TRUTH = /^(true|t|yes|y|1)$/i
  DEFAULT_NAMESPACE = "defaults".freeze

  attr_reader :features

  def self.features
    instance.features
  end

  def self.feature?(name, &block)
    name     = name.to_s
    env_name = name.upcase

    fail NotAFeature.new(name) unless features.key?(name)

    is_enabled =
      if ENV.key?(env_name)
        !!(ENV[env_name] =~ THE_TRUTH)
       else
         features[name] == true
       end

    # If no block is passed, return true or false
    return is_enabled unless block_given?

    # If a block is passed, return block or nil
    yield if is_enabled
  end

  private

  def initialize
    yaml = File.read(File.expand_path("config/features.yml", Dir.pwd))
    data = YAML.load(yaml)

    @features = (data.fetch(DEFAULT_NAMESPACE, {})).merge(data.fetch(env, {}))
  end

  def env
    rails_env || rack_env
  end

  def rails_env
    defined?(Rails) ? Rails.env : ENV["RAILS_ENV"]
  end

  def rack_env
    ENV["RACK_ENV"]
  end
end
