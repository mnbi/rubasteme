# frozen_string_literal: true

module Rubasteme

  module AST
    class LeafNode < Node
      def initialize(literal)
        super
        @literal = literal
      end

      def to_a
        [type, @literal]
      end

      def to_s
        to_a.to_s
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
