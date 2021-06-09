# frozen_string_literal: true

module Rubasteme

  def self.parser
    Parser::Parser.new
  end

  module Parser

    def self.version
      Rubasteme.send(:make_version, self.name)
    end

    module Utils
      def not_implemented_yet(feature)
        raise NotImplementedYetError, feature
      end
    end

    class Parser
      include Utils

      require_relative "parser/phase1_parser"
      require_relative "parser/phase2_parser"

      def self.version
        Rubasteme::Parser.send(:version)
      end

      def version
        self.class.version
      end

      def initialize
        @p1 = Phase1Parser.new
        @p2 = Phase2Parser.new
      end

      def parse(lexer)
        return [] if lexer.nil?
        ast_program = AST.instantiate(:ast_program, nil)
        Kernel.loop{ast_program << @p2.parse(@p1.parse(lexer))}
        ast_program
      end
    end                           # end of Parser class
  end                             # end of Parser module
end
