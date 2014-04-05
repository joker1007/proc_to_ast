require "proc_to_ast/version"

require 'parser/current'
require 'unparser'
require 'coderay'

module ProcToAst
  class MultiMatchError < StandardError; end

  class Traverser
    def traverse_node(node)
      if node.type != :block
        node.children.flat_map { |child|
          if child.is_a?(AST::Node)
            traverse_node(child)
          end
        }.compact
      else
        node
      end
    end

    def proc_block?(node)
      head = node.children[0]
      return false unless head.type == :send

      receiver, symbol = head.children

      return true if receiver.nil? && (symbol == :proc || symbol == :lambda)

      if receiver.is_a?(AST::Node) &&
        receiver.type == :const &&
        receiver.children[1] == :Proc &&
        symbol == :new

        return true
      end

      false
    end
  end
end

class Proc
  def to_ast(retry_limit = 20)
    filename, linenum = source_location
    file = File.open(filename, "rb")

    (linenum - 1).times { file.gets }
    buf = []
    try_count = 0

    parser = Parser::CurrentRuby.default_parser
    parser.diagnostics.consumer = ->(diagnostic) {} # suppress error message
    begin
      parser.reset
      try_count += 1

      buf << file.gets
      source = buf.join.force_encoding(parser.default_encoding)

      source_buffer = Parser::Source::Buffer.new(filename, linenum)
      source_buffer.source = source
      node = parser.parse(source_buffer)
      block_nodes = ProcToAst::Traverser.new.traverse_node(node)
      if block_nodes.length == 1
        block_nodes.first
      else
        raise ProcToAst::MultiMatchError
      end
    rescue Parser::SyntaxError
      retry if try_count < retry_limit
    end
  end

  def to_source(highlight: false)
    source = Unparser.unparse(to_ast)
    if highlight
      CodeRay.scan(source, :ruby).terminal
    else
      source
    end
  end
end
