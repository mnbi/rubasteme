# frozen_string_literal: true

module Rubasteme

  def self.phase1_parse(source)
    Parser::Phase1Parser.new.parse(Rbscmlex.lexer(source))
  end

  module Parser

    class Phase1Parser
      include Utils

      def self.version
        Rubasteme.send(:make_version, self.name)
      end

      def version
        self.class.version
      end

      def parse(lexer)
        return [] if lexer.nil?
        parse_expression(lexer)
      end

      # :stopdoc:
      private

      def parse_expression(lexer)
        if start_delimiter?(lexer.peek_token)
          parse_compound_expression(lexer)
        else
          parse_simple_expression(lexer)
        end
      end

      TOKEN_START_DELIMITERS = [  # :nodoc:
        :lparen,                  # list: ( ... )
        :vec_lparen,              # vector: #( ... )
        :bytevec_lparen,          # bytevector: #u8( ... )
        :quotation,               # quotation: '<something>
        :backquote,               # quasiquote: `<something>
        :comma,                   # used in quasiquote
        :comma_at,                # used in quasiquote
        :comment_lparen,          # comment start
      ]

      def start_delimiter?(token)
        TOKEN_START_DELIMITERS.include?(token.type)
      end

      def parse_simple_expression(lexer)
        type, literal = *lexer.next_token
        AST.instantiate(ast_simple_type(type), literal)
      end

      def ast_simple_type(token_type)
        case token_type
        when :identifier
          :ast_identifier
        when :boolean, :character, :number, :string
          "ast_#{token_type}".intern
        when :dot
          :ast_dot
        else
          :ast_illegal
        end
      end

      def parse_compound_expression(lexer)
        case lexer.peek_token.type
        when :vec_lparen
          parse_vector(lexer)
        when :quotation
          parse_quotation(lexer)
        when :lparen
          parse_list(lexer)
        else
          raise SchemeSyntaxErrorError, "%s" % lexer.peek_token.literal
        end
      end

      def parse_list(lexer)
        if lexer.peek_token(1).type == :rparen
          # an empty list
          lexer.skip_rparen(1)
          AST.instantiate(:ast_empty_list, nil)
        else
          nodes = []
          parse_container(nodes, lexer)
        end
      end

      def parse_vector(lexer)
        vector = AST.instantiate(:ast_vector, nil)
        parse_container(vector, lexer)
      end

      def parse_container(container, lexer)
        lexer.skip_token
        Kernel.loop {
          break if lexer.peek_token.type == :rparen
          container << parse_expression(lexer)
        }
        lexer.skip_rparen
        container
      end

      def parse_quotation(lexer)
        lexer.skip_token
        quote = AST.instantiate(:ast_identifier, "quote")
        [quote, parse_expression(lexer)]
      end

      # :startdoc:
    end                           # end of Phase1Parser
  end
end
