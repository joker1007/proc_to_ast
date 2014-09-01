# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proc_to_ast/version'

Gem::Specification.new do |spec|
  spec.name          = "proc_to_ast"
  spec.version       = ProcToAst::VERSION
  spec.authors       = ["joker1007"]
  spec.email         = ["kakyoin.hierophant@gmail.com"]
  spec.summary       = %q{Convert Proc object to AST::Node}
  spec.description   = %q{Add #to_ast method to Proc. #to_ast converts Proc object to AST::Node.}
  spec.homepage      = "https://github.com/joker1007/proc_to_ast"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "parser"
  spec.add_runtime_dependency "unparser"
  spec.add_runtime_dependency "coderay"

  spec.add_development_dependency "bundler", ">= 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.required_ruby_version = '>= 2.0.0'
end
