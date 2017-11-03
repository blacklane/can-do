require "connection_pool"
require "redis"
require "singleton"
require "yaml"

# Flips your features based on either a redis key, a config/features.yml file or environment variables.
# Redis keys always take precedence over Environment variables and the settings in your YAML file.
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
  FEATURE_KEY_PREFIX = "features:"
  CONNECTION_POOL_SIZE = ENV.fetch("CANDO_CONNECTION_POOL_SIZE", 5)
  CONNECTION_POOL = ConnectionPool.new(size: CONNECTION_POOL_SIZE, timeout: 5) do
    Redis.new(url: ENV.fetch("CANDO_REDIS_URL", nil))
  end

  THE_TRUTH = /^(true|t|yes|y|1)$/i
  DEFAULT_NAMESPACE = "defaults".freeze

  attr_reader :features

  def self.features
    instance.features
  end

  def self.shared_features(name)
    CONNECTION_POOL.with do |redis|
      begin
        redis.get(FEATURE_KEY_PREFIX + name.to_s)
      rescue Redis::BaseError
        nil
      end
    end
  end

  def self.feature?(name)
    name     = name.to_s
    env_name = name.upcase
    shared_feature = shared_features(name)

    is_enabled =
      if !shared_feature.nil?
        !!(shared_feature =~ THE_TRUTH)
      elsif ENV.key?(env_name)
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
    yaml_file = File.expand_path("config/features.yml", Dir.pwd)

    @features =
      if File.exist?(yaml_file)
        data = YAML.safe_load(File.read(yaml_file))
        data.fetch(DEFAULT_NAMESPACE, {}).merge(data.fetch(env, {}))
      else
        {}
      end
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
