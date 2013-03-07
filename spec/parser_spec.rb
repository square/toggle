require 'spec_helper'

describe Toggle::Parser do
  describe "non-found parser" do
    it "raises a parser not found error" do
      lambda {
        Toggle::Parser.for 'nonexistent-parser'
      }.should raise_error Toggle::Parser::ParserNotFound
    end
  end

  describe "'yaml' parser" do
    it "returns an instance of the Toggle Yaml parser" do
      parser = Toggle::Parser.for 'yaml'
      parser.should be_an_instance_of Toggle::Parser::YAML
    end
  end

  describe "'yml' parser" do
    it "returns an instance of the Toggle Yaml parser" do
      parser = Toggle::Parser.for 'yml'
      parser.should be_an_instance_of Toggle::Parser::YAML
    end
  end

  describe ":yaml parser" do
    it "returns an instance of the Toggle Yaml parser" do
      parser = Toggle::Parser.for :yaml
      parser.should be_an_instance_of Toggle::Parser::YAML
    end
  end

  describe ":yml parser" do
    it "returns an instance of the Toggle Yaml parser" do
      parser = Toggle::Parser.for :yml
      parser.should be_an_instance_of Toggle::Parser::YAML
    end
  end
end
