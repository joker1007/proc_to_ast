require 'spec_helper'

describe Proc do
  describe "#to_ast" do
    it "return Parser::AST::Node" do
      ast = -> { 1 + 1 }.to_ast
      expect(ast).to be_a(Parser::AST::Node)
      expect(ast.type).to eq(:block)
    end

    context "proc variation" do
      it "converts Kernel#proc" do
        pr = proc { p 1 }

        expect(pr.to_ast).to be_a(AST::Node)
      end

      it "converts Proc.new" do
        pr = Proc.new do |b|
          puts b
        end

        expect(pr.to_ast).to be_a(AST::Node)
      end

      it "converts block passing method" do
        def receive_block(&block)
          block.to_ast
        end

        block_pass = receive_block do |n|
          puts n
          [1, 2, 3].map do |i|
            i * 2
          end
        end

        block_pass2 = receive_block { %w(a b c).map(&:upcase) }

        expect(block_pass).to be_a(AST::Node)
        expect(block_pass2).to be_a(AST::Node)
      end

      it "raise ProcToAst::MultiMatchError, when other block exists on same line " do
        _ = [1].map {|i| i * 2}; fuga = ->(a) {
          p a
        }

        expect{ fuga.to_ast }.to raise_error(ProcToAst::MultiMatchError)
      end
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
