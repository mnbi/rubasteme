# frozen_string_literal: true

module Rubasteme
  module Parser

    module DerivedConverter
      include Utils

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
        cond = AST.instantiate(:ast_cond)
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
        if is_recipient_clause?(list)
          # type 3
          clause = AST.instantiate(:ast_cond_recipient_clause)
          clause.recipient = to_recipient(list[2..-1])
        else
          # type 1 and 2
          clause = AST.instantiate(:ast_cond_clause)
          clause.sequence = to_sequence(list[1..-1])
        end
        clause.test = to_test(list[0])
        clause
      end

      def is_recipient_clause?(list)
        ast_type?(list[1], :ast_identifier) && list[1].identifier == "=>"
      end

      def to_else_clause(list)
        # ( else <sequence> )
        else_clause = AST.instantiate(:ast_else_clause)
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
        # ( case <expression> <case clause>+ )
        # ( case <expression> <case clause>* ( else <sequence> ) )
        # ( case <expression> <case clause>* ( else => <recipient> ) )
        case_node = AST.instantiate(:ast_case)
        case_node.expression = parse(list[1])
        list[2..-2].each { |e|
          case_node.add_clause(to_case_clause(e))
        }
        last = list[-1]
        method = is_else_clause?(last) ? :to_case_else_clause : :to_case_clause
        case_node.add_clause(self.send(method, last))
        case_node
      end

      def to_case_clause(list)
        # ( ( <datum>* ) <sequence> )
        # ( ( <datum>* ) => <recipient> )
        if is_recipient_clause?(list)
          to_case_recipient_clause(list)
        else
          clause = AST.instantiate(:ast_case_clause)
          clause.data = to_data(list[0])
          clause.sequence = to_sequence(list[1..-1])
          clause
        end
      end

      def to_case_recipient_clause(list)
        # ( ( <datum>* ) => <recipient> )
        clause = AST.instantiate(:ast_case_recipient_clause)
        clause.data = to_data(list[0])
        caluse.recipient = to_recipient(list[2])
      end

      def to_case_else_clause(list)
        # ( else <sequence> )
        # ( else => <recipient> )
        if is_recipient_clause?(list)
          to_case_else_recipient_clause(list)
        else
          to_else_clause(list)
        end
      end

      def to_case_else_recipient_clause(list)
        # ( else => <recipient> )
        clause = AST.instantiate(:ast_else_recipient_clause)
        clause.recipient = to_recipient(list[2])
        clause
      end

      def to_data(list)
        # ( <datum>* )
        data = AST.instantiate(:ast_data)
        list.each{|e| data << parse(e)}
        data
      end

      def to_and(list)
        to_logical_test("and", list)
      end

      def to_or(list)
        to_logical_test("or", list)
      end

      def to_logical_test(type, list)
        # ( and <test>* )
        # ( or <test>* )
        ast_type = "ast_#{type}".intern
        node = AST.instantiate(ast_type)
        list[1..-1].each{|e| node << to_test(e)}
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
        node = AST.instantiate(ast_type)
        node.test = to_test(list[1])
        node.sequence = to_sequence(list[2..-1])
        node
      end

      def to_let(list)
        # ( let ( <binding spec>* ) <body> )
        # ( let <identifier> ( <binding spec>* ) <body> )
        let = AST.instantiate(:ast_let)
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
        # ( <binding spec>* )
        bindings = AST.instantiate(:ast_bindings)
        list.each { |e|
          bindings.add_bind_spec(to_bind_spec(e))
        }
        bindings
      end

      def to_bind_spec(list)
        # ( <identifier> <expression> )
        spec = AST.instantiate(:ast_bind_spec)
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
        # ( letrec ( <binding spec>* ) <body> )
        # ( letrec* ( <binding spec>* ) <body> )
        ast_type = "ast_#{type}".intern
        node = AST.instantiate(ast_type)
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
        # ( begin <sequence> )
        begin_node = AST.instantiate(:ast_begin)
        begin_node.sequence = to_sequence(list[1..-1])
        begin_node
      end

      def to_do(list)
        # ( do ( <iteration spec>* ) ( <test> <do result> ) <command>* )
        do_node = AST.instantiate(:ast_do)
        do_node.iteration_bindings = to_iteration_bindings(list[1])
        do_node.test_and_do_result = to_test_and_do_result(list[2])
        list[3..-1].each { |e|
          do_node.add_command(parse(e))
        }
        do_node
      end

      def to_iteration_bindings(list)
        # ( <iteration spec>* )
        node = AST.instantiate(:ast_iteration_bindings)
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
        spec = AST.instantiate(:ast_iteration_spec)
        spec.identifier = list[0]
        spec.init = parse(list[1])
        if list.size > 2
          spec.step = parse(list[2])
        end
        spec
      end

      def to_test_and_do_result(list)
        # ( <test> <do result> )
        # <do result> -> <sequence> | <empty>
        node = AST.instantiate(:ast_test_and_do_result)
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

    end

  end                           # end of Parser (module)
end
