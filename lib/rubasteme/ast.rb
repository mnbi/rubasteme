# frozen_string_literal: true

module Rubasteme

  def self.write(ast_node, of = STDOUT)
    of.puts ast_node.to_s
  end

  module AST

    AST_NODE_TYPE = [           # :nodoc:
      # leaf
      :ast_empty_list,
      :ast_boolean,
      :ast_identifier,
      :ast_character,
      :ast_string,
      :ast_number,
      :ast_dot,
      # branch
      :ast_program,
      :ast_list,
      :ast_vector,
      :ast_quotation,
      :ast_procedure_call,
      :ast_lambda_expression,
      :ast_formals,
      :ast_conditional,
      :ast_assignment,
      :ast_identifier_definition,
      :ast_cond,
      :ast_cond_clause,
      :ast_case,
      :ast_and,
      :ast_or,
      :ast_when,
      :ast_unless,
      :ast_let,
      :ast_let_star,
      :ast_letrec,
      :ast_letrec_star,
      :ast_bindings,
      :ast_bind_spec,
      :ast_begin,
      :ast_do,
      :ast_iteration_bindings,
      :ast_test_and_do_result,
      :ast_iteration_spec,
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
      def to_s; to_a.to_s; end
    end

    require_relative "ast/leaf_node"
    require_relative "ast/branch_node"

    class IllegalNode < Node
      def initialize(type, literal)
        super(literal)
        @given_type = type
        @literal = literal
      end

      def to_a
        [type, @given_type, @literal]
      end
    end

  end
end
