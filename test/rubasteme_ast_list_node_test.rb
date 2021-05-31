# frozen_string_literal: true

require "test_helper"

class RubastemeASTListNodeTest < Minitest::Test
  def test_it_can_be_instantiate
    node = list_node
    refute_nil node
  end

  def test_it_can_detect_it_has_no_child_nodes
    node = list_node
    assert_empty node
  end

  def test_it_can_retrieve_the_first_node
    node = list_node
    child = child_nodes(1)
    add_children(node, [child])
    assert child.equal?(node.first)
  end

  def test_it_can_retrieve_the_rest_nodes
    node = list_node
    children = child_nodes(3)
    add_children(node, children)
    assert_equal children[1..-1], node.rest
  end

  def test_it_can_retrieve_all_child_nodes_in_an_array
    node = list_node
    children = child_nodes(5)
    add_children(node, children)
    assert_equal children, node.elements
  end

  private

  def list_node(num_of_children = nil)
    Rubasteme::AST.instantiate(:ast_list, nil)
  end

  def child_nodes(n)
    children = []
    n.times{children << list_node}
    children
  end

  def add_children(node, children)
    children.each {|e| node << e}
  end

end
