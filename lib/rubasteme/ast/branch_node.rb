# frozen_string_literal: true

module Rubasteme

  module AST

    class BranchNode < Node
      def initialize(_ = nil)
        super
        @nodes = []
      end

      def size
        @nodes.size
      end

      def to_a
        @nodes.map(&:to_a)
      end

      def to_s
        "[" + @nodes.map(&:to_s).join(", ") + "]"
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
        super
      end

      def to_a
        [type, super]
      end

      def to_s
        to_a.to_s
      end
    end

    class VectorNode < BranchNode
      def initialize(_ = nil)
        super
      end

      def to_a
        [type, super]
      end
    end

    class ListNode < BranchNode
      def initialize(_ = nil)
        super
      end
    end

  end                           # end of AST

end
