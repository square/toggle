require 'spec_helper'

describe Toggle do
  let(:config_filepath) { File.join(FIXTURES_PATH, 'config.yml') }

  describe "#configs" do
    let(:toggle) { described_class.new config_filepath: config_filepath }

    it "returns compiled content for the specified config file as a hash" do
      toggle.configs.should == {
        'local' => {
          'plain_attribute' => 'local_plain_attribute_value',
          'erb_attribute'   => 'local_erb_attribute_value'
        },
        'remote' => {
          'plain_attribute' => 'remote_plain_attribute_value',
          'erb_attribute'   => 'remote_erb_attribute_value'
        }
      }
    end
  end

  describe "#key" do
    let(:toggle) { described_class.new }

    it "returns the specified attribute as a symbol" do
      toggle.key = 'something'
      toggle.key.should == :something
    end

    it "returns the flat value when file has no extension" do
      toggle.key_filepath = File.join(FIXTURES_PATH, 'flat-key-local')
      toggle.key.should == :local
    end

    it "returns the compiled key as a symbol from the key file if no key attribute is set" do
      toggle.key_filepath = File.join(FIXTURES_PATH, 'key-local.yml')
      toggle.key.should == :local
    end

    it "returns the set key attribute as a symbol over the compiled key file's key value" do
      toggle.key = 'something'
      toggle.key_filepath = File.join(FIXTURES_PATH, 'key-local.yml')
      toggle.key.should == :something
    end
  end

  describe "#config" do
    let(:toggle) { described_class.new }

    it "returns the config data that corresponds to #key" do
      toggle.config_filepath = config_filepath
      toggle.key = :local
      toggle.config.should == {
        'plain_attribute' => 'local_plain_attribute_value',
        'erb_attribute'   => 'local_erb_attribute_value'
      }
    end
  end

  describe "#[]" do
    let(:key)    { :local }
    let(:toggle) { described_class.new config_filepath: config_filepath, key: key }

    it "indifferently returns the value corresponding to the passed argument for the loaded config" do
      toggle['plain_attribute'].should == 'local_plain_attribute_value'
      toggle[:plain_attribute].should  == 'local_plain_attribute_value'
    end
  end

  describe "#using" do
    let(:toggle) { described_class.new config_filepath: config_filepath }

    it "does not raise an exception when a block is not supplied" do
      lambda {
        toggle.using(:no_block)
      }.should_not raise_error
    end

    it "allows block access to the specified configs data without changing internal state" do
      toggle.key = :local

      toggle.using(:remote) do |config|
        config[:plain_attribute].should == 'remote_plain_attribute_value'
        config[:erb_attribute].should   == 'remote_erb_attribute_value'
      end

      toggle.config.should == {
        'plain_attribute' => 'local_plain_attribute_value',
        'erb_attribute'   => 'local_erb_attribute_value'
      }
    end
  end
end
