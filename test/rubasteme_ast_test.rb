# frozen_string_literal: true

require "test_helper"

class RubastemeASTTest < Minitest::Test
  def test_it_can_instantiate_program_node
    node = Rubasteme::AST.instantiate(:ast_program, nil)
    refute_nil node
  end

  def test_it_can_instantiate_illegal_node
    node = Rubasteme::AST.instantiate(:ast_illegal, nil)
    refute_nil node
  end

end
