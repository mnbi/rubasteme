# frozen_string_literal: true

module Rubasteme

  module AST
    class LeafNode < Node
      def initialize(literal)
        super
        @literal = literal
      end

      attr_reader :literal

      def to_a
        [type, @literal]
      end
    end

    class EmptyListNode < LeafNode
      def initialize(_ = nil)
        super("()")
      end
    end

    class BooleanNode < LeafNode
      def initialize(literal)
        super
      end
    end

    class IdentifierNode < LeafNode
      def initialize(literal)
        super
      end
    end

    class CharacterNode < LeafNode
      def initialize(literal)
        super
      end
    end

    class StringNode < LeafNode
      def initialize(literal)
        super
      end
    end

    class NumberNode < LeafNode
      def initialize(literal)
        super
      end
    end

    class DotNode < LeafNode
      def initialize(literal)
        super
      end
    end

  end                           # end of AST
end
