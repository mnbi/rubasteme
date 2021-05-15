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

  end                           # end of AST

end
