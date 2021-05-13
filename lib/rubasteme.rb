# frozen_string_literal: true

require "rbscmlex"

module Rubasteme

  def self.lexer(obj)
    Rbscmlex::Lexer.new(obj)
  end

  require_relative "rubasteme/error"
  require_relative "rubasteme/utils"
  require_relative "rubasteme/ast"
  require_relative "rubasteme/parser"
  require_relative "rubasteme/version"
end
