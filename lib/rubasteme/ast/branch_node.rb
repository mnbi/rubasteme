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
      def initialize(first_literal = nil, initial_size = nil)
        super(initial_size)
        @nodes[0] = AST.instantiate(:ast_identifier, first_literal) if first_literal
      end
    end

    class QuotationNode < ListNode
      def initialize(_ = nil)
        super("quote")
      end
    end

    class ProcedureCallNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<operator>, <operand>*]
        super(nil, 1)
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
        # @nodes = ["lambda", <formals>, <body>, ...]
        super("lambda", 2)
      end

      def formals
        @nodes[1]
      end

      def formals=(list_node)
        @nodes[1] = list_node
      end

      def body
        @nodes[2..-1]
      end

      def body=(nodes)
        nodes.each_with_index { |node, i|
          @nodes[i + 2] = node
        }
      end
    end

    class ConditionalNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<if>, <test>, <consequent>] or
        #          [<if>, <test>, <consequent>, <alternate>]
        super("if", 3)
      end

      def test
        @nodes[1]
      end

      def test=(node)
        @nodes[1] = node
      end

      def consequent
        @nodes[2]
      end

      def consequent=(node)
        @nodes[2] = node
      end

      def alternate
        @nodes[3]
      end

      def alternate=(node)
        @nodes[3] = node
      end
    end

    class AssignmentNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<set!>, <identifier>, <expression>]
        super("set!", 3)
      end

      def identifier
        @nodes[1]
      end

      def identifier=(node)
        @nodes[1] = node
      end

      def expression
        @nodes[2]
      end

      def expression=(node)
        @nodes[2] = node
      end
    end

    class IdentifierDefinitionNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<define>, <identifier>, <expression>]
        #   <expression> might be a lambda expression.
        super("define", 3)
      end

      def identifier
        @nodes[1]
      end

      def identifier=(node)
        @nodes[1] = node
      end

      def expression
        @nodes[2]
      end

      def expression=(node)
        @nodes[2] = node
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

    class AndNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<and>, <test>, ...]
        super("and", 1)
      end
    end

    class OrNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<or>, <test>, ...]
        super("or", 1)
      end
    end

  end                           # end of AST

end
