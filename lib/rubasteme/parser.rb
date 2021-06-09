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
      def ast?(obj)
        obj.kind_of?(AST::Node)
      end

      def ast_type?(obj, type)
        ast?(obj) && obj.type == type
      end

      def not_implemented_yet(feature)
        raise NotImplementedYetError, feature
      end
    end

    require_relative "parser/phase1_parser"
    require_relative "parser/phase2_parser"

    class Parser
      include Utils

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
        ast_program = AST.instantiate(:ast_program)
        Kernel.loop{ast_program << @p2.parse(@p1.parse(lexer))}
        ast_program
      end
    end                           # end of Parser class
  end                             # end of Parser module
end
