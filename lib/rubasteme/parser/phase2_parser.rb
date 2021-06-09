# frozen_string_literal: true

module Rubasteme

  def self.phase2_parse(source)
    nodes = Parser::Phase1Parser.new.parse(Rbscmlex.lexer(source))
    Parser::Phase2Parser.new.parse(nodes)
  end

  module Parser

    class Phase2Parser
      include Utils

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

      def ast?(obj)
        obj.kind_of?(AST::Node)
      end

      def ast_type?(obj, type)
        ast?(obj) && obj.type == type
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

      def to_ast(list)
        if list.empty?
          AST.instantiate(:ast_empty_list, nil)
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
        else
          # TODO: it it correct?
          list
        end
      end

      def to_quotation(list)
        quote = AST.instantiate(:ast_quotation, nil)
        quote << list
        quote
      end

      def to_procedure_call(list)
        proc_call = AST.instantiate(:ast_procedure_call, nil)
        proc_call.operator = list[0]
        list[1..-1].each { |node|
          proc_call.add_operand(parse(node))
        }
        proc_call
      end

      def to_lambda_expression(list)
        lambda_exp = AST.instantiate(:ast_lambda_expression, nil)
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
          formals = AST.instantiate(:ast_formals, nil)
          list.each{|e| formals.add_identifier(e)}
          formals
        end
      end

      def to_body(list)
        body = AST.instantiate(:ast_body, nil)
        definitions = AST.instantiate(:ast_internal_definitions, nil)

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
        seq = AST.instantiate(:ast_sequence, nil)
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
        define = AST.instantiate(:ast_identifier_definition, nil)

        if ast_type?(list[1], :ast_identifier)
          # type 1 and type 2
          define.identifier = list[1]
          define.expression = parse(list[2])
        elsif list[1].instance_of?(Array)
          # type 3:
          #   make a lambda expression, then handle as type 2
          lambda_exp = AST.instantiate(:ast_lambda_expression, nil)
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
        if_node = AST.instantiate(:ast_conditional, nil)
        if_node.test = parse(list[1])
        if_node.consequent = parse(list[2])

        if list.size > 3
          if_node.alternate = parse(list[3])
        end

        if_node
      end

      def to_assignment(list)
        assignment = AST.instantiate(:ast_assignment, nil)
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

      def to_derived_expression(list)
        name = compose_method_name("to_", list[0].identifier).intern
        if self.respond_to?(name, true)
          self.send(name, list)
        else
          not_implemented_yet(list[0])
        end
      end

      def to_cond(list)
        # ( cond <cond clause> ... <else clause> )
        cond = AST.instantiate(:ast_cond, nil)
        list[1..-2].each { |e|
          cond.add_clause(to_cond_clause(e))
        }
        last = list[-1]
        method = is_else_clause?(last) ? :to_else_clause : :to_cond_clause
        cond.add_clause(self.send(method, last))
        cond
      end

      def is_else_clause?(list)
        ast_type?(list[0], :ast_identifier) && list[0].identifier == "else"
      end

      def to_cond_clause(list)
        # type 1: ( <test> )
        # type 2: ( <test> <sequence> )
        # type 3: ( <test> => <recipient> )
        clause = nil
        if ast_type?(list[1], :ast_identifier) && list[1].identifier == "=>"
          # type 3
          clause = AST.instantiate(:ast_cond_recipient_clause, nil)
          clause.recipient = to_recipient(list[2..-1])
        else
          # type 1 and 2
          clause = AST.instantiate(:ast_cond_clause, nil)
          clause.sequence = to_sequence(list[1..-1])
        end
        clause.test = to_test(list[0])
        clause
      end

      def to_else_clause(list)
        # ( else <sequence> )
        else_clause = AST.instantiate(:ast_else_clause, nil)
        else_clause.sequence = to_sequence(list[1..-1])
        else_clause
      end

      def to_test(list)
        # <test> -> <expression>
        parse(list)
      end

      def to_recipient(list)
        # <recipient> -> <expression>
        parse(list)
      end

      def to_case(list)
        not_implemented_yet("CASE")
      end

      def to_and(list)
        to_logical_test("and", list)
      end

      def to_or(list)
        to_logical_test("or", list)
      end

      def to_logical_test(type, list)
        ast_type = "ast_#{type}".intern
        node = AST.instantiate(ast_type, nil)
        list[1..-1].each{|e| node << parse(e)}
        node
      end

      def to_when(list)
        to_test_and_sequence("when", list)
      end

      def to_unless(list)
        to_test_and_sequence("unless", list)
      end

      def to_test_and_sequence(type, list)
        # ( when <test> <sequence> )
        # ( unless <test> <sequence> )
        ast_type = "ast_#{type}".intern
        node = AST.instantiate(ast_type, nil)
        node.test = to_test(list[1])
        node.sequence = to_sequence(list[2..-1])
        node
      end

      def to_let(list)
        let = AST.instantiate(:ast_let, nil)
        bindings_pos = 1
        if ast_type?(list[1], :ast_identifier)
          # named let
          let.identifier = list[1]
          bindings_pos += 1
        end
        let.bindings = to_bindings(list[bindings_pos])
        let.body = to_body(list[(bindings_pos + 1)..-1])
        let
      end

      def to_bindings(list)
        bindings = AST.instantiate(:ast_bindings, nil)
        list.each { |e|
          bindings.add_bind_spec(to_bind_spec(e))
        }
        bindings
      end

      def to_bind_spec(list)
        spec = AST.instantiate(:ast_bind_spec, nil)
        spec.identifier = list[0]
        spec.expression = parse(list[1])
        spec
      end


      def to_let_star(list)
        to_let_base("let_star", list)
      end

      def to_letrec(list)
        to_let_base("letrec", list)
      end

      def to_letrec_star(list)
        to_let_base("letrec_star", list)
      end

      def to_let_base(type, list)
        # ( let* ( <binding spec>* ) <body> )
        ast_type = "ast_#{type}".intern
        node = AST.instantiate(ast_type, nil)
        node.bindings = to_bindings(list[1])
        node.body = to_body(list[2..-1])
        node
      end

      def to_let_values(list)
        not_implemented_yet("LET-VALUES")
      end

      def to_let_star_values(list)
        not_implemented_yet("LET*-VALUES")
      end

      def to_begin(list)
        begin_node = AST.instantiate(:ast_begin, nil)
        begin_node.sequence = to_sequence(list[1..-1])
        begin_node
      end

      def to_do(list)
        # ( do ( <iteration spec>* ) ( <test> <do result> ) <command>* )
        do_node = AST.instantiate(:ast_do, nil)
        do_node.iteration_bindings = to_iteration_bindings(list[1])
        do_node.test_and_do_result = to_test_and_do_result(list[2])
        list[3..-1].each { |e|
          do_node.add_command(parse(e))
        }
        do_node
      end

      def to_iteration_bindings(list)
        node = AST.instantiate(:ast_iteration_bindings, nil)
        list.each { |e|
          node.add_iteration_spec(to_iteration_spec(e))
        }
        node
      end

      def to_iteration_spec(list)
        # ( <identifier> <init> )
        # ( <identifier> <init> <step> )
        # <init> -> <expression>
        # <step> -> <expression>
        spec = AST.instantiate(:ast_iteration_spec, nil)
        spec.identifier = list[0]
        spec.init = parse(list[1])
        if list.size > 2
          spec.step = parse(list[2])
        end
        spec
      end

      def to_test_and_do_result(list)
        node = AST.instantiate(:ast_test_and_do_result, nil)
        node.test = to_test(list[0])
        node.sequence = to_sequence(list[1..-1])
        node
      end

      def to_delay(list)
        not_implemented_yet("DELAY")
      end

      def to_delay_force(list)
        not_implemented_yet("DELAY-FORCE")
      end

      def to_parameterize(list)
        not_implemented_yet("PARAMETERIZE")
      end

      def to_guard(list)
        not_implemented_yet("GUARD")
      end

      def to_case_lambda(list)
        not_implemented_yet("CASE-LAMBDA")
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
