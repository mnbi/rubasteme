# frozen_string_literal: true

module Rubasteme

  def self.write(ast_node, of = STDOUT)
    of.puts ast_node.to_s
  end

  module AST

    AST_NODE_TYPE = [           # :nodoc:
      # leaf
      :ast_boolean,
      :ast_identifier,
      :ast_character,
      :ast_string,
      :ast_number,
      :ast_dot,
      # branch
      :ast_program,
      :ast_list,
      # misc.
      :ast_illegal,
    ]

    def self.instantiate(ast_node_type, literal)
      type_name = Utils.camel_case(ast_node_type.to_s.delete_prefix("ast_"))
      klass = AST.const_get("#{type_name}Node")

      if klass.nil? or klass == IllegalNode
        IllegalNode.new(ast_node_type, literal)
      else
        klass.new(literal)
      end
    end

    class Node
      def initialize(_literal = nil)
      end

      def type
        klass_name = self.class.name.split("::")[-1]
        type_name = Utils.snake_case(klass_name.delete_suffix("Node"))
        "ast_#{type_name}".intern
      end

      def to_a; []; end
      def to_s; ""; end
    end

    require_relative "ast/leaf_node"
    require_relative "ast/branch_node"

    class IllegalNode < Node
      def initialize(type, literal)
        super(literal)
        @given_type = type
        @literal = literal
      end
    end

  end
end
