# Rubasteme

[![Build Status](https://github.com/mnbi/rubasteme/workflows/Build/badge.svg)](https://github.com/mnbi/rubasteme/actions?query=workflow%3A"Build")

Simple Abstract Syntax Tree and a parser for Scheme written in Ruby.

It is intended to be used as a part of a Scheme implementation written
in Ruby.

- Rubasteme is a set of classes to represent an AST for Scheme language.
  - Currently (in 0.1.0), it does support partially the language
    specification of Scheme.
- Rubasteme does not provide any features for lexical analysis.
  - Instead, it uses `rbscmlex` to execute lexical analysis of Scheme
    program.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubasteme'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rubasteme

## Usage

See the directory, `examples`.  There are 2 small implementations of
subset for Scheme language.  Though both have very limited
capabilities as Scheme interpreter, they can execute the following
code:

``` scheme
(define (fact n)
  (define (fact-iter n r c)
    (if (< n c)
	r
	(fact-iter n (* r c) (+ c 1))))
  (fact-iter n 1 1))

(display (fact 10))
(display (fact 100))
(display (fact 1000))
```

``` scheme
(define (iota-iter result count start step)
  (if (zero? count)
      result
      (iota-iter (append result (list start))
		 (- count 1)
		 (+ start step)
		 step)))

(define (iota count start step)
  (iota-iter () count start step))

(display (iota 10 1 1))
(display (iota 10 1/9 11/99))
```

### How to execute

1. Save the above code in a file.
2. Run `examples/mini_rus3` or `examples/mini_sicp_scheme`
3. Input `(load "some_file.scm")` after the prompt, then hit return key.

Or, input any arbitrary expressions after the prompt.  Note that the
current REPL does not support to input expression in multi-lines.
Each expression must be input entirely in a single line.

### mini Rus3 (`mini_rus3`)

It is intended to show how to use Ruby classes of AST nodes.

### SICP Scheme (`mini_sicp_scheme`)

It is intended to show how to use AST nodes those are represented as
"tagged Array."

## Abstract Syntax Tree

### Supported Types

- empty list
- boolean
- identifier
- character
- string
- number
- program
- list
- quotation
- procedure call
- lambda expression
- conditional
- assignment
- identifier definition
- cond
- and
- or
- when
- unless
- let
- let*
- letrec
- letrec*
- do

## TODO

- Add more documentation.
- Implement more types.
- Re-factor code.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/mnbi/rubasteme](https://github.com/mnbi/rubasteme).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
