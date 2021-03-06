# frozen_string_literal: true

require "connection_pool"
require "redis"
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
  CONNECTION_POOL_SIZE = ENV.fetch("CANDO_CONNECTION_POOL_SIZE", 5)
  CONNECTION_POOL = ConnectionPool.new(size: CONNECTION_POOL_SIZE, timeout: 5) do
    Redis.new(url: ENV["CANDO_REDIS_URL"])
  end

  THE_TRUTH = /^(true|t|yes|y|1)$/i
  DEFAULT_NAMESPACE = "defaults"
  REDIS_ERRORS = [Redis::CannotConnectError, SocketError, RuntimeError]
  # hiredis raises RuntimeError when it cannot connect to the redis server

  class << self
    def feature?(feature)
      is_enabled = read(feature)
      # If no block is passed, return true or false
      return is_enabled unless block_given?

      # If a block is passed, return block or nil
      yield if is_enabled
    end

    def read(feature)
      name = feature.to_s
      shared_feature = redis_read(name)
      fallback_value = fallback.fetch(name, false)

      return !!(shared_feature =~ THE_TRUTH) unless shared_feature.nil?

      write(name, fallback_value)
      fallback_value
    rescue *REDIS_ERRORS
      fallback_value
    end

    def write(name, val)
      pool.with { |redis| redis.set(redis_key(name), val) } == "OK"
    rescue *REDIS_ERRORS
      false
    end

    def features
      keys = pool.with { |redis| redis.keys(redis_key("*")) }
      keys.map { |key| key.sub(redis_key(nil), "") }
    rescue *REDIS_ERRORS
      []
    end

    def redis_read(name)
      pool.with { |redis| redis.get(redis_key(name)) }
    end

    private

    def redis_key(name)
      "#{redis_namespace}:#{name}"
    end

    def pool
      CONNECTION_POOL
    end

    def fallback
      @fallback ||= init_fallback
    end

    def yaml_file_path
      File.expand_path("config/features.yml", Dir.pwd)
    end

    def init_fallback
      features = load_yaml_features

      features.each do |key, val|
        begin
          write(key, redis_read(key) || val)
        rescue *REDIS_ERRORS
        end
      end

      features
    end

    def load_yaml_features
      return {} unless File.exist?(yaml_file_path)

      data = YAML.safe_load(File.read(yaml_file_path))
      data.fetch(DEFAULT_NAMESPACE, {}).merge(data.fetch(env, {}))
    end

    def env
      ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    end

    def redis_namespace
      "features"
    end
  end
end
