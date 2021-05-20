# frozen_string_literal: true

require "test_helper"

class RubastemeParserTest < Minitest::Test
  def test_it_can_get_instance_of_parser
    parser = Rubasteme.parser
    refute_nil parser
  end
end
