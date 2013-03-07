class Toggle
  class Compiler
    class FileNotFound < RuntimeError; end

    def initialize file, parsers = nil
      @file    = file
      @parsers = parsers ? [*parsers] : file_extensions
    end

    def parsed_content
      @parsers.reduce(raw_file_content) do |content, parser|
        Toggle::Parser.for(parser).parse content if content
      end
    end

    private

    def file_extensions
      parts = File.basename(@file).split(".")
      parts[1, parts.length - 1]
    end

    def raw_file_content
      begin
        File.read(@file).chomp
      rescue ::Errno::ENOENT => e
        raise FileNotFound.new e.message
      end
    end
  end
end
