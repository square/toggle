# YAML Parser handles erb parsing first, then loads the content to yaml
class Toggle
  module Parser
    class YAML
      def parse content
        require 'erb'
        require 'yaml'
        ::YAML.load(::ERB.new(content).result.chomp)
      end
    end
  end
end
