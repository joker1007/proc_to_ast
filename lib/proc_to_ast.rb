require "proc_to_ast/version"

require 'parser/current'
require 'unparser'
require 'coderay'

module ProcToAst
  class MultiMatchError < StandardError; end

  class Parser
    attr_reader :parser

    def initialize
      @parser = ::Parser::CurrentRuby.default_parser
      @parser.diagnostics.consumer = ->(diagnostic) {} # suppress error message
    end

    # Read file and try parsing
    # if success parse, find proc AST
    #
    # @param filename [String] reading file path
    # @param linenum [Integer] start line number
    # @param retry_limit [Integer]
    # @return [Parser::AST::Node] Proc AST
    def parse(filename, linenum, retry_limit = 20)
      @filename, @linenum = filename, linenum
      file = File.open(filename, "rb")

      (linenum - 1).times { file.gets }
      buf = []
      try_count = 0

      begin
        try_count += 1

        buf << file.gets
        do_parse(buf.join)
      rescue ::Parser::SyntaxError => e
        node = trim_and_retry(buf)

        return node unless node.nil?
        retry if try_count < retry_limit

        raise e
      ensure
        file.close
      end
    end

    private

    def do_parse(source)
      parser.reset

      source_buffer = ::Parser::Source::Buffer.new(@filename, @linenum)
      source_buffer.source = source
      node = parser.parse(source_buffer)
      block_nodes = traverse_node(node)

      if block_nodes.length == 1
        block_nodes.first
      else
        raise ProcToAst::MultiMatchError
      end
    end

    # Remove tail comma and wrap dummy method, and retry parsing
    # For proc inner Array or Hash
    def trim_and_retry(buf)
      *lines, last = buf

      # For inner Array or Hash or Arguments list.
      lines << last.gsub(/,\s*$/, "")
      do_parse("a(#{lines.join})") # wrap dummy method
    rescue ::Parser::SyntaxError
    end

    def traverse_node(node)
      if node.type != :block
        node.children.flat_map { |child|
          if child.is_a?(AST::Node)
            traverse_node(child)
          end
        }.compact
      else
        [node]
      end
    end
  end
end

class Proc
  # @param retry_limit [Integer]
  # @return [Parser::AST::Node] Proc AST
  def to_ast(retry_limit = 20)
    filename, linenum = source_location
    parser = ProcToAst::Parser.new
    parser.parse(filename, linenum, retry_limit)
  end

  # @param highlight [Boolean] enable output highlight
  # @param retry_limit [Integer]
  # @return [String] proc source code
  def to_source(highlight: false, retry_limit: 20)
    source = Unparser.unparse(to_ast(retry_limit))
    if highlight
      CodeRay.scan(source, :ruby).terminal
    else
      source
    end
  end

  def to_raw_source(highlight: false, retry_limit: 20)
    source = to_ast(retry_limit).loc.expression.source

    if highlight
      CodeRay.scan(source, :ruby).terminal
    else
      source
    end
  end
end
