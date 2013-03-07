require 'toggle/version'
require 'toggle/compiler'
require 'toggle/parser'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string'

class Toggle
  attr_writer   :key
  attr_accessor :key_parsers
  attr_accessor :key_filepath
  attr_accessor :config_parsers
  attr_accessor :config_filepath

  def initialize attributes = {}
    attributes.keys.each do |attribute|
      self.send "#{attribute}=", attributes[attribute]
    end
  end

  def [] attribute
    config[attribute]
  end

  def config_filepath= value
    configs_dirty! unless @config_filepath.eql? value
    @config_filepath = value
  end

  def key
    (@key || key_from_file).try(:to_sym)
  end

  def config
    configs[key]
  end

  def configs
    return @configs if defined?(@configs) && configs_clean?

    @configs = HashWithIndifferentAccess.new(
      Toggle::Compiler.new(
        config_filepath,
        config_parsers
      ).parsed_content
    )
    configs_clean!
    @configs
  end

  def using temporary_key
    return unless block_given?

    previous_key, self.key = self.key, temporary_key
    yield self
    self.key = previous_key
  end

private

  def key_from_file
    Toggle::Compiler.new(
      key_filepath,
      key_parsers
    ).parsed_content if key_filepath
  end

  def configs_clean?
    @configs_clean
  end

  def configs_dirty!
    @configs_clean = false
  end

  def configs_clean!
    @configs_clean = true
  end
end
