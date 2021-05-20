# coding: utf-8
# frozen_string_literal: true

require "test_helper"

class RubastemeParserTest < Minitest::Test
  def setup
    @parser = Rubasteme.parser
  end

  def test_it_can_get_instance_of_parser
    parser = Rubasteme.parser
    refute_nil parser
  end

  def test_it_can_instantiate_ast_program
    ast = parse("123")
    assert_kind_of Rubasteme::AST::ProgramNode, ast
    assert_equal :ast_program, ast.type
  end

  def test_it_can_parse_boolean
    tcs = ["#f", "#false", "#t", "#true"]
    assert_simple_expression_type(tcs, Rubasteme::AST::BooleanNode, :ast_boolean)
  end

  def test_it_can_parse_identifier
    tcs = ["foo", "hoge", "if", "define", "cond", "else"]
    assert_simple_expression_type(tcs, Rubasteme::AST::IdentifierNode, :ast_identifier)
  end

  def test_it_can_parse_character
    tcs = ['#\a', '#\あ', '#\newline', '#\space']
    assert_simple_expression_type(tcs, Rubasteme::AST::CharacterNode, :ast_character)
  end

  def test_it_can_parse_string
    tcs = ['"foo"', '"hoge"', '"if"', '"define"', '"cond"', '"else"']
    assert_simple_expression_type(tcs, Rubasteme::AST::StringNode, :ast_string)
  end

  def test_it_can_parse_number
    tcs = ["123", "-1", "+23", "456.7890123", "1/2", "333/4444",
           "5+6i", "7.0-8.9i", "-0+1i", "-2-3i"]
    assert_simple_expression_type(tcs, Rubasteme::AST::NumberNode, :ast_number)
  end

  def test_it_can_parse_dot
    tcs = ["."]
    assert_simple_expression_type(tcs, Rubasteme::AST::DotNode, :ast_dot)
  end

  def test_it_cap_parse_operator
    tcs = ["+", "-", "*", "/", "%", "<", ">", "<=", ">=", ]
    assert_simple_expression_type(tcs, Rubasteme::AST::IdentifierNode, :ast_identifier)
  end

  def test_it_can_parse_vector
    tcs = ["#()", "#(1)", "#(2 3)", "#(3 #(4 5))",]
    tcs.each { |src, expected|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::VectorNode, node
      assert_equal :ast_vector, node.type
    }
  end

  def test_it_can_parse_quoted_datum
    tcs = ["\'1", "\'foo", "\'(1 2)",]
    tcs.each { |src|
      ast = parse(src)
      node = ast[0]
      assert_kind_of Rubasteme::AST::QuotationNode, node
      assert_equal :ast_quotation, node.type
    }
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
