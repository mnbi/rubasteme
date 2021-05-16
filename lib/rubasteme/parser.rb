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
      type, literal = *@lexer.next_token
      AST.instantiate(ast_simple_type(type), literal)
    end

    def parse_identifier
      parse_simple_expression
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
        raise SchemeSyntaxError, @lexer.peek_token.literal
      end
    end

    def parse_vector
      parse_data_to_matched_rparen
    end

    def parse_quotation
      literal = @lexer.next_token.literal
      quote_node = AST.instantiate(:ast_quotation, literal)
      quote_node << parse_datum
      quote_node
    end

    DERIVED_IDENTIFIERS = [
      "cond", "case", "and", "or", "when", "unless",
      "let", "let*", "letrec", "letrec*",
      "let-values", "let*-values",
      "begin", "do",
      "delay", "delay-force",
      "parameterize",
      "guard",
      "case-lambda",
    ]

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
        when *DERIVED_IDENTIFIERS
          node = parse_derived_expression
        else
          node = parse_macro_use
        end
      end
      node || parse_procedure_call
    end

    def parse_procedure_call
      proc_call_node = AST.instantiate(:ast_procedure_call, nil)
      proc_call_node.operator = parse_operator
      Kernel.loop {
        break if @lexer.peek_token.type == :rparen
        proc_call_node.add_operand(parse_operand)
      }
      @lexer.skip_token         # skip :rparen
      proc_call_node
    end

    def parse_operator
      parse_expression
    end

    def parse_operand
      parse_expression
    end

    def parse_lambda_expression
      @lexer.skip_token         # skip :lparen
      lambda_node = make_lambda_expression_node(parse_formals, read_body)
      @lexer.skip_token         # skip :rparen
      lambda_node
    end

    def make_lambda_expression_node(formals, body)
      lambda_node = AST.instantiate(:ast_lambda_expression, nil)
      lambda_node.formals = formals
      lambda_node.body = body
      lambda_node
    end

    def parse_formals
      type, literal = *@lexer.next_token
      formals = nil
      if type == :lparen
        formals = AST.instantiate(:ast_list, nil)
        Kernel.loop {
          type, literal = *@lexer.next_token
          break if type == :rparen
          formals << AST.instantiate(:ast_identifier, literal)
        }
      else
        formals = AST.instantiate(:ast_identifier, literal)
      end
      formals
    end

    def read_body
      body = []
      Kernel.loop {
        break if @lexer.peek_token.type == :rparen # the end of lambda exp.
        body << parse_expression
      }
      body
    end

    def parse_conditional
      if_node = AST.instantiate(:ast_conditional, @lexer.next_token.literal)
      if_node.test = parse_test
      if_node.consequent = parse_consequent
      if @lexer.peek_token.type != :rparen
        if_node.alternate = parse_alternate
      end
      @lexer.skip_token         # skip :rparen
      if_node
    end

    def parse_test
      parse_expression
    end

    def parse_consequent
      parse_expression
    end

    def parse_alternate
      parse_expression
    end

    def parse_assignment
      assignment_node = AST.instantiate(:ast_assignment, @lexer.next_token.literal)
      assignment_node.identifier = parse_identifier
      assignment_node.expression = parse_expression
      @lexer.skip_token         # skip :rparen
      assignment_node
    end

    def parse_macro_block
      not_implemented_yet("MACRO block")
    end

    def parse_definition
      case @lexer.peek_token.literal
      when "define"
        parse_identifier_definition
      when "define-syntax"
        parse_define_syntax
      when "define-values"
        parse_define_values
      when "define-record-type"
        parse_define_record_type
      when "begin"
        parse_begin
      else
        raise SchemeSyntaxErrorError, @lexer.peek_token.literal
      end
    end

    def parse_identifier_definition
      # type 1: (define foo 3)
      # type 2: (define bar (lambda (x y) (+ x y)))
      # type 3: (define (hoge n m) (display n) (display m) (* n m))
      define_node = AST.instantiate(:ast_identifier_definition, @lexer.next_token.literal)

      case @lexer.peek_token.type
      when :identifier
        # type 1 and type 2
        define_node.identifier = parse_identifier
        define_node.expression = parse_expression
        @lexer.skip_token       # skip :rparen
      when :lparen
        # type 3:
        #   make a lambda expression, then handle as type 2
        @lexer.skip_token       # skip :lparen
        define_node.identifier = parse_identifier
        def_formals_node = AST.instantiate(:ast_list, nil)
        Kernel.loop {
          break if @lexer.peek_token.type == :rparen
          def_formals_node << parse_identifier
        }
        @lexer.skip_token       # skip :rparen
        lambda_node = make_lambda_expression_node(def_formals_node, read_body)
        @lexer.skip_token       # skip :rparen
        define_node.expression = lambda_node
      else
        raise SchemeSyntaxErrorError, @lexer.peek_token.literal
      end

      define_node
    end

    def parse_define_syntax
      not_implemented_yet("DEFINE-SYNTAX")
    end

    def parse_define_values
      not_implemented_yet("DEFINE-VALUES")
    end

    def parse_define_record_type
      not_implemented_yet("DEFINE-RECORD-TYPE")
    end

    def parse_begin
      not_implemented_yet("BEGIN")
    end

    def parse_includer
      not_implemented_yet("INCLUDE or INCLUDE-CI")
    end

    def parse_derived_expression
      literal = @lexer.next_token.literal
      name = compose_method_name("parse_", literal).intern
      if self.respond_to?(name)
        m = self.method(name)
        m.call
      else
        not_implemented_yet(literal)
      end
    end

    def parse_and
      parse_logical_test("and")
    end

    def parse_or
      parse_logical_test("or")
    end

    def parse_logical_test(literal)
      ast_type = "ast_#{literal}".intern
      node = AST.instantiate(ast_type, nil)
      Kernel.loop {
        break if @lexer.peek_token.type == :rparen
        node << parse_test
      }
      @lexer.skip_token
      node
    end

    def parse_cond
      not_implemented_yet("COND")
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

    SCM_CHAR_TO_RB_MAP = {
      "*" => "_star",
      "-" => "_",
    }

    def compose_method_name(prefix, type_name)
      converted_name = type_name.gsub(/[*\-]/, SCM_CHAR_TO_RB_MAP)
      prefix + converted_name
    end

    def not_implemented_yet(feature)
      raise NotImplementedYetError, feature
    end

  end                           # end of Parser class

end
