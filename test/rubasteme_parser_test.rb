# frozen_string_literal: true

require "test_helper"

class DummyLexer
end

class RubastemeParserTest < Minitest::Test
  def test_it_can_get_instance_of_parser
    lexer = DummyLexer.new
    parser = Rubasteme.parser(lexer)
    refute_nil parser
  end
end
