# frozen_string_literal: true

module Rubasteme

  def self.parser(lexer)
    Parser.new(lexer)
  end

  class Parser

    def initialize(lexer)
      @lexer = lexer
    end

    def parse
      return [] if @lexer.nil?
      parse_program
    end

    def parse_program
      ast_program = AST.instantiate(:ast_program, nil)
      Kernel.loop {
        ast_program << parse_expression
      }
      ast_program
    end

    def parse_expression
      if start_delimiter?(@lexer.peek_token)
        parse_compound_expression
      else
        parse_simple_expression
      end
    end

    def parse_simple_expression
      token = @lexer.next_token
      AST.instantiate(ast_simple_type(token.type), token.literal)
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

    def parse_compound_expression
      node = nil

      case @lexer.peek_token.type
      when :vec_lparen
        node = parse_vector
      else
        node = parse_simple_expression
      end

      node
    end

    def parse_vector
      parse_data_to_matched_rparen
    end

    def parse_data_to_matched_rparen
      token = @lexer.next_token
      node = AST.instantiate(ast_compound_type(token.type), token.literal)
      Kernel.loop {
        break if @lexer.peek_token.type == :rparen
        node << parse_datum
      }
      @lexer.next_token         # skip :rparen

      node
    end

    def parse_datum
      if start_delimiter?(@lexer.peek_token)
        parse_compound_datum
      else
        parse_simple_datum
      end
    end

    def parse_simple_datum
      parse_simple_expression
    end

    def parse_compound_datum
      case @lexer.peek_token.type
      when :vec_lparen
        parse_vector
      else
        parse_simple_expression
      end
    end

    private

    def ast_simple_type(token_type)
      case token_type
      when :identifier
        :ast_identifier
      when :boolean, :character, :number, :string
        "ast_#{token_type}".intern
      when :dot
        :ast_dot
      else
        :ast_identifier
      end
    end

    def ast_compound_type(token_type)
      case token_type
      when :vec_lparen
        :ast_vector
      else
        :ast_list
      end
    end

  end

end
