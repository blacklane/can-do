require "spec_helper"

RSpec.describe CanDo do
  subject(:can_do) { CanDo.clone }
  let(:redis) { Redis.new }
  let(:redis_namespace) { "can-do-test" }

  before do
    redis.keys("#{redis_namespace}:*").each { |key| redis.del(key) }
    allow(can_do).to receive(:redis_namespace) { redis_namespace }
  end

  describe "no feature set" do
    it "does not raise" do
      expect { can_do.feature?(:no_valid_feature) }.not_to raise_error
    end

    it "does return false" do
      expect(can_do.feature?(:no_valid_feature)).to eq(false)
    end
  end

  describe "reading from redis" do
    before do
      redis.set("#{redis_namespace}:redis_feature", true)
    end

    it "uses the redis value" do
      expect(can_do.feature?(:redis_feature)).to eq(true)
    end
  end

  describe "reading value from fallback" do
    before do
      allow(can_do).to receive(:fallback) { { "fallback_feature" => true } }
    end

    let(:result) { can_do.feature?(:fallback_feature) }

    it "reads the value from fallback" do
      expect(result).to be(true)
    end

    it "persists the value to redis" do
      expect { result }
        .to change { redis.get("#{redis_namespace}:fallback_feature") }
        .to("true")
    end
  end

  describe "fail to read from redis" do
    let(:redis_adapter) { double("CanDo::RedisAdapter") }

    before do
      allow(redis_adapter).to receive(:read) { failure }
      allow(can_do).to receive(:redis) { redis_adapter }
    end

    context "key in fallback" do
      before do
        allow(can_do).to receive(:fallback) { { "fallback_feature" => true } }
      end

      it "reads the value from fallback" do
        expect(can_do.feature?(:fallback_feature)).to eq(true)
      end
    end

    context "no key in fallback" do
      it "defaults to false" do
        expect(can_do.feature?(:fallback_feature)).to eq(false)
      end
    end
  end

  describe "writing to redis" do
    let(:redis_adapter) { double("CanDo::RedisAdapter") }
    let(:write) { can_do.write("feature", false) }

    before do
      allow(can_do).to receive(:redis) { redis_adapter }
    end

    context "success" do
      it "returns true" do
        expect(write).to be(true)
      end
    end

    context "failure" do
      before do
        allow(can_do).to receive(:pool) { raise Redis::CannotConnectError }
      end

      it "returns false" do
        expect(write).to be(false)
      end
    end

    context "dns failure" do
      before do
        allow(can_do).to receive(:pool) { raise SocketError }
      end

      it "returns false" do
        expect(write).to be(false)
      end
    end
  end

  describe "yaml defaults" do
    include_context "reads yaml file"
    before { allow(can_do).to receive(:env) { nil } }

    it "uses the default value" do
      expect(can_do.feature?(:feature)).to eq(true)
      expect(can_do.feature?(:other_feature)).to eq(false)
    end
  end

  describe "yaml defaults for environment" do
    include_context "reads yaml file"
    before { allow(can_do).to receive(:env) { "test" } }

    it "uses the env value" do
      expect(can_do.feature?(:feature)).to eq(false)
      expect(can_do.feature?(:other_feature)).to eq(true)
    end
  end

  describe "listing features" do
    before do
      redis.set("#{redis_namespace}:feature_one", true)
      redis.set("#{redis_namespace}:feature_two", true)
      redis.set("#{redis_namespace}:feature_three", true)
      redis.set("not-#{redis_namespace}:non_feature", true)
    end

    it "fetches the list of features from redis" do
      features = can_do.features
      expect(features.size).to be(3)
      expect(features).to include "feature_one"
      expect(features).to include "feature_two"
      expect(features).to include "feature_three"
    end
  end
end
