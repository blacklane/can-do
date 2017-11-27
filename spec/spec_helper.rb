require "bundler/setup"
require "can_do"
require "pry"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end
end

RSpec.shared_context "reads yaml file" do
  let(:yaml_file_path) { "features.yml" }
  let(:yaml_config) do
    <<-YAML
    defaults: {feature: true, other_feature: false}
    test: {feature: false, other_feature: true}
    YAML
  end

  before do
    allow(can_do).to receive(:yaml_file_path) { yaml_file_path }
    allow(File).to receive(:exist?).with(yaml_file_path) { true }
    allow(File).to receive(:read).with(yaml_file_path) { yaml_config }
  end
end
