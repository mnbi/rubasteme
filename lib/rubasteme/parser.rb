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
      case @lexer.peek_token.type
      when :vec_lparen
        parse_vector
      when :quotation
        parse_quotation
      when :lparen
        parse_list_expression
      else
        # TODO: raise an error
        parse_simple_expression
      end
    end

    def parse_vector
      parse_data_to_matched_rparen
    end

    def parse_quotation
      token = @lexer.next_token
      quote_node = AST.instantiate(:ast_quotation, token.literal)
      quote_node << parse_datum
      quote_node
    end

    def parse_list_expression
      node = nil
      @lexer.skip_token         # skip :lparen
      case @lexer.peek_token.type
      when :rparen
        # an empty list
        node = AST.instantiate(:ast_empty_list, nil)
      when :identifier
        case @lexer.peek_token.literal
        when "lambda"
          node = parse_lambda_expression
        when "if"
          node = parse_conditional
        when "set!"
          node = parse_assignment
        when "let-syntax", "letrec-syntax"
          node = parse_macro_block
        when "define", "define-syntax", "define-values", "define-record-type", "begin"
          node = parse_definition
        when "include", "include-ci"
          node = parse_includer
        else
          node = parse_derived_expression
          node = parse_macro_use if node.nil?
        end
      end
      node || parse_procedure_call
    end

    def parse_procedure_call
      proc_call_node = AST.instantiate(:ast_procedure_call, nil)
      proc_call_node.operator = parse_operator
      Kernel.loop {
        if @lexer.peek_token.type == :rparen
          @lexer.skip_token
          break
        end
        proc_call_node.add_operand(parse_operand)
      }
      proc_call_node
    end

    def parse_operator
      parse_expression
    end

    def parse_operand
      parse_expression
    end

    def parse_lambda_expression
      lambda_node = AST.instantiate(:ast_lambda_expression, @lexer.next_token.literal)
      lambda_node.formals = parse_formals
      lambda_node.body = read_body
      @lexer.skip_token         # skip :rparen
      lambda_node
    end

    def parse_formals
      token = @lexer.next_token
      formals = nil
      if token.type == :lparen
        formals = AST.instantiate(:ast_list, nil)
        Kernel.loop {
          token = @lexer.next_token
          break if token.type == :rparen
          formals << AST.instantiate(:ast_identifier, token.literal)
        }
      else
        formals = AST.instantiate(:ast_identifier, token.literal)
      end
      formals
    end

    def read_body
      body = []
      Kernel.loop {
        break if @lexer.peek_token.type == :rparen
        body << parse_expression
      }
      body
    end

    def parse_conditional
      nil
    end

    def parse_assignment
      nil
    end

    def parse_macro_block
      nil
    end

    def parse_definition
      nil
    end

    def parse_includer
      nil
    end

    def parse_derived_expression
      nil
    end

    def parse_macro_use
      nil
    end

    def parse_data_to_matched_rparen
      token = @lexer.next_token
      node = AST.instantiate(ast_compound_type(token.type), nil)
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
      when :lparen
        parse_list
      when :vec_lparen
        parse_vector
      else
        parse_simple_expression
      end
    end

    def parse_list
      parse_data_to_matched_rparen
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
