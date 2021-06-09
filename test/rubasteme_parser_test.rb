# coding: utf-8
# frozen_string_literal: true

require "test_helper"

class RubastemeParserTest < Minitest::Test
  def setup
    @parser = Rubasteme.parser
  end

  # issue #8
  def test_it_can_generate_proc_call_node_even_if_operator_is_lambda_exp
    source = "((lambda (n) (+ n 1)) 3)"
    ast = parse(source)
    node = ast[0]
    assert_equal :ast_procedure_call, node.type
    operator = node[0]
    assert_equal :ast_lambda_expression, operator.type
  end

  # end of issue #8

  # issue #5
  def test_it_raise_error_if_internal_definition_is_at_wrong_position
    source = "(define (foo x) (+ x 1) (define y 4) (* x y))"
    assert_raises(Rubasteme::SchemeSyntaxErrorError) {
     _ = parse(source)
    }
  end

  def test_it_can_handle_internal_definition
    source = "(define (foo x) (define (hoge y) (+ y 1)) (hoge x))"
    ast = parse(source)
    node = ast[0]
    assert_equal :ast_identifier_definition, node.type
    assert_equal :ast_internal_definitions, node.expression.body.definitions.type
    refute node.expression.body.definitions.empty?
  end

  # end of issue #5

  def test_it_can_get_instance_of_parser
    parser = Rubasteme.parser
    refute_nil parser
  end

  def test_it_can_instantiate_ast_program
    ast = parse("123")
    assert_kind_of Rubasteme::AST::ProgramNode, ast
    assert_equal :ast_program, ast.type
  end

  def test_it_can_parse_procedure_call
    tcs = [
      "(foo)",
      "(bar 1)",
      "(hoge 1 2)",
      "(gebo 1 (boho 1 2 3))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::ProcedureCallNode, node
      assert_equal :ast_procedure_call, node.type
    }
  end

  def test_it_can_parse_lambda_expression
    tcs = [
      "(lambda (x y) (+ x y))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::LambdaExpressionNode, node
      assert_equal :ast_lambda_expression, node.type
    }
  end

  def test_it_can_parse_conditional
    tcs = [
      "(if (= n 0) 1 (* n n))",
      "(if (> n 1) (+ n 1))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::ConditionalNode, node
      assert_equal :ast_conditional, node.type
    }
  end

  def test_it_can_parse_assignment
    tcs = [
      "(set! x 3)",
      "(set! x (* 4 5))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::AssignmentNode, node
      assert_equal :ast_assignment, node.type
    }
  end

  def test_it_can_parse_identifier_definition
    tcs = [
      "(define foo 3.14)",
      "(define bar \"BAR\")",
      "(define hoge (list 1 2 3))",
      "(define gebo (lambda (x y) (+ x y)))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::IdentifierDefinitionNode, node
      assert_equal :ast_identifier_definition, node.type
    }
  end

  def test_it_can_parse_proc_definition
    tcs = [
      "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::IdentifierDefinitionNode, node
      assert_equal :ast_identifier_definition, node.type
      assert_equal :ast_lambda_expression, node.expression.type
    }
  end

  def test_it_can_parse_cond
    tcs = [
      "(cond ((< n 0) (write \"negative\")))",
      "(cond ((< n 0) (write \"negative\")) ((= n 0) (write \"zero\")))",
      "(cond ((< n 0) (write \"negative\")) ((= n 0) (write \"zero\")) (else (write \"positive\")))",
    ]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::CondNode, node
      assert_equal :ast_cond, node.type
    }
  end

  private

  def parse(src)
    lexer = Rbscmlex::Lexer.new(src)
    @parser.parse(lexer)
  end

  def assert_simple_expression_type(tcs, klass, type)
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of klass, node
      assert_equal type, node.type
    }
  end
end
