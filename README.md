# proc_to_ast
[![Gem Version](https://badge.fury.io/rb/proc_to_ast.svg)](http://badge.fury.io/rb/proc_to_ast)
[![Build Status](https://travis-ci.org/joker1007/proc_to_ast.svg?branch=master)](https://travis-ci.org/joker1007/proc_to_ast)

Add `#to_ast` method to Proc.

`#to_ast` convert Proc to `Parser::AST::Node`, using [parser](https://github.com/whitequark/parser "whitequark/parser") gem.

## Installation

Add this line to your application's Gemfile:

    gem 'proc_to_ast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install proc_to_ast

## Usage

```ruby
require 'proc_to_ast'

foo = proc { p(1 + 1) }

foo.to_ast
# =>
# (block
#   (send nil :proc)
#   (args)
#   (send nil :p
#     (send
#       (int 1) :+
#       (int 1))))

foo.to_source
# => "proc do\n  p(1 + 1)\nend"

foo.to_source(highlight: true)
# => "proc \e[32mdo\e[0m\n  p(\e[1;34m1\e[0m + \e[1;34m1\e[0m)\n\e[32mend\e[0m"
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/proc_to_ast/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
