# coding: utf-8
# frozen_string_literal: true

require "test_helper"

class RubastemeParserPhase1ParserTest < Minitest::Test
  def setup
    @parser = Rubasteme::Parser::Phase1Parser.new
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
    assert_simple_expression_type(tcs, Rubasteme::AST::VectorNode, :ast_vector)
  end

  def test_it_can_parse_quoted_datum
    tcs = ["\'1", "\'foo", "\'(1 2)",]
    tcs.each { |src|
      node = parse(src)
      assert_kind_of Array, node
      assert_kind_of Rubasteme::AST::IdentifierNode, node[0]
      assert_equal "quote", node[0].identifier
    }
  end

  private

  def parse(src)
    lexer = Rbscmlex::Lexer.new(src)
    @parser.parse(lexer)
  end

  def assert_simple_expression_type(tcs, klass, type)
    tcs.each { |src|
      node = parse(src)
      assert_kind_of klass, node
      assert_equal type, node.type
    }
  end
end
