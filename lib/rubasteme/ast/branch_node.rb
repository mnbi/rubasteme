# frozen_string_literal: true

module Rubasteme

  module AST

    class BranchNode < Node
      def initialize(initial_size = nil)
        super(nil)
        @nodes = initial_size.nil? ? [] : Array.new(initial_size)
      end

      def size
        @nodes.size
      end

      def to_a
        [type, @nodes.map(&:to_a)]
      end

      def to_s
        to_a.to_s
      end

      include Enumerable

      def each(&blk)
        if block_given?
          @nodes.each(&blk)
          self
        else
          @nodes.each
        end
      end

      def [](index)
        @nodes[index]
      end

      def []=(index, node)
        @nodes[index] = node
      end

      def <<(node)
        @nodes << node
      end
    end

    class ProgramNode < BranchNode
      def initialize(_ = nil)
        super(nil)
      end
    end

    class VectorNode < BranchNode
      def initialize(_ = nil)
        super(nil)
      end
    end

    class ListNode < BranchNode
      def initialize(_ = nil)
        super(nil)
      end
    end

    class QuotationNode < ListNode
      def initialize(_ = nil)
        super(nil)
      end
    end

    class ProcedureCallNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<operator>, <operand>*]
        super(1)
      end

      def operator
        @nodes[0]
      end

      def operator=(node)
        @nodes[0] = node
      end

      def operands
        @nodes[1..-1]
      end

      def add_operand(node)
        @nodes << node
      end
    end

    class LambdaExpressionNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<formals>, <body>, ...]
        super(1)
      end

      def formals
        @nodes[0]
      end

      def formals=(list_node)
        @nodes[0] = list_node
      end

      def body
        @nodes[1..-1]
      end

      def body=(nodes)
        nodes.each_with_index { |node, i|
          @nodes[i + 1] = node
        }
      end
    end

    class ConditionalNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, <consequent>] or
        #          [<test>, <consequent>, <alternate>]
        super(1)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end

      def consequent
        @nodes[1]
      end

      def consequent=(node)
        @nodes[1] = node
      end

      def alternate
        @nodes[2]
      end

      def alternate=(node)
        @nodes[2] = node
      end
    end

    class AssignmentNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<identifier>, <expression>]
        super(2)
      end

      def identifier
        @nodes[0]
      end

      def identifier=(node)
        @nodes[0] = node
      end

      def expression
        @nodes[1]
      end

      def expression=(node)
        @nodes[1] = node
      end
    end

    class IdentifierDefinitionNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<identifier>, <expression>]
        #   <expression> might be a lambda expression.
        super(2)
      end

      def identifier
        @nodes[0]
      end

      def identifier=(node)
        @nodes[0] = node
      end

      def expression
        @nodes[1]
      end

      def expression=(node)
        @nodes[1] = node
      end

      def def_formals
        lambda? ? expression.formals : nil
      end

      def body
        lambda? ? expression.body : nil
      end

      private

      def lambda?
        expression.type == :ast_lambda_expression
      end
    end

    class CondNode < ListNode
      def initialize(_ = nil)
        super(nil)
      end

      def cond_clause
        @nodes[0..-1]
      end

      def add_clause(node)
        @nodes << node
      end
    end

    class CondClauseNode < ListNode
      # @nodes = [<test>, <sequence>]
      def initialize(_ = nil)
        super(nil)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end

      def sequence
        @nodes[1..-1]
      end

      def add_expression(node)
        @nodes << node
      end
    end

    class AndNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, ...]
        super(nil)
      end
    end

    class OrNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, ...]
        super(nil)
      end
    end

    class TestAndSequenceNode < ListNode
      def initialize(_ = nil)
        super(1)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end

      def sequence
        @nodes[1..-1]
      end

      def add_sequence(node)
        @nodes << node
      end
    end

    class WhenNode < TestAndSequenceNode
    end

    class UnlessNode < TestAndSequenceNode
    end

    class LetNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<bind specs>, <body>, ...] or
        #          [<identifier>, <bind specs>, <body>, ...]
        super(1)
      end

      def identifier
        named_let? ? @nodes[0] : nil
      end

      def identifier=(node)
        @nodes.insert(0, node) if node.type == :ast_identifier
      end

      def bind_specs
        named_let? ? @nodes[1] : @nodes[0]
      end

      def bind_specs=(node)
        if named_let?
          @nodes[1] = node
        else
          @nodes[0] = node
        end
      end

      def body
        named_let? ? @nodes[2..-1] : @nodes[1..-1]
      end

      def body=(nodes)
        start_pos = named_let? ? 2 : 1
        nodes.each_with_index { |node, i|
          @nodes[start_pos + i] = node
        }
      end

      private

      def named_let?
        @nodes[0].nil? ? false : @nodes[0].type == :ast_identifier
      end
    end

    class LetBaseNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<bind specs>, <body>, ...]
        super(1)
      end

      def bind_specs
        @nodes[0]
      end

      def bind_specs=(node)
        @nodes[0] = node
      end

      def body
        @nodes[1..-1]
      end

      def body=(nodes)
        nodes.each_with_index { |node, i|
          @nodes[1 + i] = node
        }
      end
    end

    class LetStarNode < LetBaseNode
    end

    class LetrecNode < LetBaseNode
    end

    class LetrecStarNode < LetBaseNode
    end

    class BindSpecNode < ListNode
      def initialize(_ = nil)
        super(2)
      end

      def identifier
        @nodes[0]
      end

      def identifier=(node)
        @nodes[0] = node
      end

      def expression
        @nodes[1]
      end

      def expression=(node)
        @nodes[1] = node
      end
    end

    class BeginNode < ListNode
      def initialize(_ = nil)
        super(nil)
      end
    end

  end                           # end of AST

end
