class Toggle
  module Parser
    class ParserNotFound < StandardError; end

    def self.for type
      case type.to_s.downcase
      when 'yaml', 'yml'
        require 'toggle/parser/yaml'
        ::Toggle::Parser::YAML.new
      else
        raise ParserNotFound, <<-EOS
          #{type} is not currently implemented. You should write it!
        EOS
      end
    end
  end
end
