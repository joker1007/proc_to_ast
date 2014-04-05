require 'spec_helper'

describe Proc do
  describe "#to_ast" do
    it "return Parser::AST::Node" do
      ast = -> { 1 + 1 }.to_ast
      expect(ast).to be_a(Parser::AST::Node)
      expect(ast.type).to eq(:block)
    end

    it "converts proc variation" do
      hoge = proc { p 1 }

      _ = [1].map {|i| i * 2}; fuga = ->(a) {
        p a
      }

      foo = Proc.new do |b|
        puts b
      end

      def receive_block(&block)
        block.to_ast
      end

      block_pass = receive_block do |n|
        puts n
      end

      expect(hoge.to_ast).to be_a(AST::Node)
      expect{ fuga.to_ast }.to raise_error(ProcToAst::MultiMatchError)
      expect(foo.to_ast).to be_a(AST::Node)
      expect(block_pass).to be_a(AST::Node)
    end
  end

  describe "#to_source" do
    it "return source code string" do
      fuga = ->(a) {
        p a
      }

      expect(fuga.to_source).to eq("lambda do |a|\n  p(a)\nend")
      expect(fuga.to_source(highlight: true)).to eq("lambda \e[32mdo\e[0m |a|\n  p(a)\n\e[32mend\e[0m")
    end
  end
end
