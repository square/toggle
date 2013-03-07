require 'spec_helper'
require 'toggle/parser/yaml'

describe Toggle::Parser::YAML do
  describe "parse" do
    let(:parser) { Toggle::Parser::YAML.new }

    it "parses the passed content, converting erb tags" do
      parser.parse("Hello world <%= 40 + 2 %>").should == "Hello world 42"
    end

    it "parses the passed content, serializing as yaml" do
      parser.parse(":hello: world").should == {hello: 'world'}
    end
  end
end
