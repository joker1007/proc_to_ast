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
    # @return [Parser::AST::Node] Proc AST
    def parse(filename, linenum)
      @filename, @linenum = filename, linenum
      buf = []
      File.open(filename, "rb").each_with_index do |line, index|
        next if index < linenum - 1
        buf << line
        begin
          return do_parse(buf.join)
        rescue ::Parser::SyntaxError
          node = trim_and_retry(buf)
          return node if node
        end
      end
      fail(::Parser::SyntaxError, 'Unknown error')
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
  # @return [Parser::AST::Node] Proc AST
  def to_ast
    filename, linenum = source_location
    parser = ProcToAst::Parser.new
    parser.parse(filename, linenum)
  end

  # @param highlight [Boolean] enable output highlight
  # @return [String] proc source code
  def to_source(highlight: false)
    source = Unparser.unparse(to_ast)
    if highlight
      CodeRay.scan(source, :ruby).terminal
    else
      source
    end
  end

  def to_raw_source(highlight: false)
    source = to_ast.loc.expression.source

    if highlight
      CodeRay.scan(source, :ruby).terminal
    else
      source
    end
  end
end
