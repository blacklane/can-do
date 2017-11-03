require "spec_helper"

RSpec.describe CanDo do
  let(:redis) do
    Redis.new
  end

  describe "no feature set" do
    it "does not raise" do
      expect { CanDo.feature?(:no_valid_feature) }.not_to raise_error
    end

    it "does return false" do
      expect(CanDo.feature?(:no_valid_feature)).to eq(false)
    end
  end

  describe "environment variable set" do
    before do
      ENV["ENV_FEATURE"] = "true"
    end

    after do
      ENV.delete("ENV_FEATURE")
    end

    it "does ignore the yaml configuration" do
      expect(CanDo.feature?(:env_feature)).to eq(true)
    end

    it "does not load the yaml file" do
      expect(File).not_to receive(:exist?)
      CanDo.feature?(:env_feature)
    end
  end

  describe "redis feature set" do
    before do
      redis.set("features:redis_feature", true)
    end

    after do
      redis.del("features:redis_feature")
    end

    it "uses the redis value" do
      expect(CanDo.feature?(:redis_feature)).to eq(true)
    end
  end

  describe "yaml feature set" do
    let(:yaml_config) { "yaml_feature: true" }

    before do
      expect(CanDo).to receive(:features).and_return(YAML.safe_load(yaml_config))
    end

    it "uses the yaml value" do
      expect(CanDo.feature?(:yaml_feature)).to eq(true)
    end
  end
end
