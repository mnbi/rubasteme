# frozen_string_literal: true

module Rubasteme

  def self.phase2_parse(source)
    nodes = Parser::Phase1Parser.new.parse(Rbscmlex.lexer(source))
    Parser::Phase2Parser.new.parse(nodes)
  end

  module Parser

    require_relative "derived_converter"

    class Phase2Parser
      include Utils
      include DerivedConverter

      def self.version
        Rubasteme.send(:make_version, self.name)
      end

      def version
        self.class.version
      end

      def parse(list)
        if ast?(list)
          list
        elsif list.instance_of?(Array)
          to_ast(list)
        else
          raise SchemeSyntaxErrorError,
                "unknown syntax element; got=%s" % node.to_s
        end
      end

      # :stopdoc:
      private

      def to_ast(list)
        if list.empty?
          AST.instantiate(:ast_empty_list)
        elsif ast_type?(list[0], :ast_identifier)
          node = nil
          case list[0].identifier
          when "quote"
            node = to_quotation(list)
          when "lambda"
            node = to_lambda_expression(list)
          when "if"
            node = to_conditional(list)
          when "set!"
            node = to_assignment(list)
          when "let-syntax", "letrec-syntax"
            node = to_macro_block(list)
          when "define", "define-syntax", "define-values", "define-record-type"
            node = to_definition(list)
          when "include", "include-ci"
            node = to_include(list)
          when *DERIVED_IDENTIFIERS
            node = to_derived_expression(list)
          end
          node || to_procedure_call(list)
        elsif list[0].instance_of?(Array)
          to_procedure_call(list)
        else
          raise SchemeSyntaxErrorError,
                "invalid application; got=%s" % list.to_a.to_s
        end
      end

      def to_quotation(list)
        quote = AST.instantiate(:ast_quotation)
        quote << list
        quote
      end

      def to_procedure_call(list)
        proc_call = AST.instantiate(:ast_procedure_call)
        proc_call.operator = list[0]
        list[1..-1].each { |node|
          proc_call.add_operand(parse(node))
        }
        proc_call
      end

      def to_lambda_expression(list)
        # ( lambda <formals> <body> )
        lambda_exp = AST.instantiate(:ast_lambda_expression)
        lambda_exp.formals = to_formals(list[1])
        lambda_exp.body = to_body(list[2..-1])
        lambda_exp
      end

      def to_formals(list)
        # type 1: <identifier>
        # type 2: ( <identifier 1> <identifier 2> ... )
        # type 3: ( <identifier 1> <identifier 2> <dot> <identifier n> )
        #   => not supported yet
        if ast_type?(list, :ast_identifier)
          # type 1
          list
        else
          # type 2
          formals = AST.instantiate(:ast_formals)
          list.each{|e| formals.add_identifier(e)}
          formals
        end
      end

      def to_body(list)
        # <body> -> <definition>* <sequence>
        body = AST.instantiate(:ast_body)
        definitions = AST.instantiate(:ast_internal_definitions)

        i = 0
        list.each { |e|
          break unless is_definition?(e)
          definitions.add_definition(to_definition(e))
          i += 1
        }
        body.definitions = definitions

        body.sequence = to_sequence(list[i..-1])
        body
      end

      def to_sequence(list)
        # <sequence> -> <command>* <expression>
        # <command> -> <expression>
        seq = AST.instantiate(:ast_sequence)
        list.each { |node|
          if is_definition?(node)
            raise SchemeSyntaxErrorError,
                  "wrong position of internal definition"
          end
          seq.add_expression(parse(node))
        }
        seq
      end

      DEFINITION_IDENTIFIERS = [
        "define",
        "define-syntax",
        "define-values",
        "define-record-type",
      ]

      def is_definition?(list)
        list.instance_of?(Array) &&
          ast_type?(list[0], :ast_identifier) &&
          DEFINITION_IDENTIFIERS.include?(list[0].identifier)
      end

      def to_definition(list)
        case list[0].identifier
        when "define"
          to_identifier_definition(list)
        when "define-syntax"
          to_define_syntax(list)
        when "define-values"
          to_define_values(list)
        when "define-record-type"
          to_define_record_type(list)
        else
          raise SchemeSyntaxErrorError, "not definition got=%s" % list[0].identifier
        end
      end

      def to_identifier_definition(list)
        # type 1: (define foo 3)
        # type 2: (define bar (lambda (x y) (+ x y)))
        # type 3: (define (hoge n m) (display n) (display m) (* n m))
        define = AST.instantiate(:ast_identifier_definition)

        if ast_type?(list[1], :ast_identifier)
          # type 1 and type 2
          define.identifier = list[1]
          define.expression = parse(list[2])
        elsif list[1].instance_of?(Array)
          # type 3:
          #   make a lambda expression, then handle as type 2
          lambda_exp = AST.instantiate(:ast_lambda_expression)
          lambda_exp.formals = to_formals(list[1][1..-1])
          lambda_exp.body = to_body(list[2..-1])

          define.identifier = list[1][0]
          define.expression = lambda_exp
        else
          raise SchemeSyntaxErrorError, "got=%s" % list[1].to_s
        end

        define
      end

      def to_define_syntax(ast_node)
        not_implemented_yet("DEFINE-SYNTAX")
      end

      def to_define_values(ast_node)
        not_implemented_yet("DEFINE-VALUES")
      end

      def to_define_record_type(ast_node)
        not_implemented_yet("DEFINE-RECORD-TYPE")
      end

      def to_includer(ast_node)
        not_implemented_yet("INCLUDE or INCLUDE-CI")
      end

      def to_conditional(list)
        # ( if <test> <consequent> )
        # ( if <test> <consequent> <alternate> )
        if_node = AST.instantiate(:ast_conditional)
        if_node.test = parse(list[1])
        if_node.consequent = parse(list[2])

        if list.size > 3
          if_node.alternate = parse(list[3])
        end

        if_node
      end

      def to_assignment(list)
        # ( set! <identifier> <expression>)
        assignment = AST.instantiate(:ast_assignment)
        assignment.identifier = list[1]
        assignment.expression = parse(list[2])
        assignment
      end

      def to_macro_block(list)
        not_implemented_yet("MACRO BLOCK")
      end

      def to_include(list)
        not_implemented_yet("INCLUDE")
      end

      SCM_CHAR_TO_RB_MAP = {
        "*" => "_star",
        "-" => "_",
      }

      def compose_method_name(prefix, type_name)
        converted_name = type_name.gsub(/[*\-]/, SCM_CHAR_TO_RB_MAP)
        prefix + converted_name
      end

      # :startdoc:
    end                         # end of Phase2Parser
  end                           # end of Parser
end
