# frozen_string_literal: true

require "rbscmlex"
require_relative "rbscmlex/missing"

module Rubasteme

  def self.lexer(obj)
    Rbscmlex::Lexer.new(obj)
  end

  def self.parse(source)
    parser.parse(lexer(source))
  end

  require_relative "rubasteme/error"
  require_relative "rubasteme/utils"
  require_relative "rubasteme/ast"
  require_relative "rubasteme/parser"
  require_relative "rubasteme/version"
end
