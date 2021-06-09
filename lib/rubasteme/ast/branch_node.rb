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
        [type].concat(@nodes.map(&:to_a))
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
      def initialize(initial_size = 0, _ = nil)
        super(initial_size)
      end

      def empty?
        @nodes.empty?
      end

      def first
        @nodes[0]
      end

      def rest
        @nodes[1..-1]
      end

      def elements
        @nodes
      end
    end

    class QuotationNode < ListNode
      def initialize(_ = nil)
        super(0, nil)
      end
    end

    class ProcedureCallNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<operator>, <operand>*]
        super(1, _)
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
        # @nodes = [<formals>, <body>]
        super(2, _)
      end

      def formals
        @nodes[0]
      end

      def formals=(node)
        @nodes[0] = node
      end

      def body
        @nodes[1]
      end

      def body=(node)
        @nodes[1] = node
      end
    end

    class FormalsNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<identifier 1>, <identifier 2>, ... ]
        super(0, nil)
      end

      def add_identifier(node)
        @nodes << node
      end
    end

    class HoldingSequenceBaseNode < ListNode
      def initialize(initial_size = 0, sequence_pos = 0, _ = nil)
        # @nodes = [..., <sequence>, ...]
        super(initial_size, _)
        @sequence_pos = sequence_pos
      end

      def sequence
        @nodes[@sequence_pos]
      end

      def sequence=(node)
        @nodes[@sequence_pos] = node
      end
    end

    class BodyNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # @nodes = [<definitions>, <sequence>]
        super(2, 1, _)
      end

      def definitions
        @nodes[0]
      end

      def definitions=(node)
        @nodes[0] = node
      end
    end

    class InternalDefinitionsNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<definition 1>, <definition 2>, ... ]
        super(0, nil)
      end

      def add_definition(node)
        @nodes << node
      end
    end

    class SequenceNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<expression 1>, <expression 2>, ... ]
        super(0, _)
      end

      def add_expression(node)
        @nodes << node
      end
    end

    class ConditionalNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, <consequent>] or
        #          [<test>, <consequent>, <alternate>]
        super(2, _)
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

      def alternate?
        !@nodes[2].nil?
      end
    end

    class AssignmentNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<identifier>, <expression>]
        super(2, _)
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
        super(2, _)
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
        super(0, _)
      end

      def cond_clauses
        @nodes[0..-1]
      end

      def add_clause(node)
        @nodes << node
      end
    end

    class CondClauseNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # type 1: @nodes = [<test>, <sequence>]
        # type 2: @nodes = [<test>]
        #   - <sequence> is empty
        super(2, 1, _)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end
    end

    class RecipientClauseBaseNode < ListNode
      def initialize(initial_size = 0, recipient_pos = 0, _ = nil)
        # @nodes = [<recipient>]
        # <recipient> -> <expression>
        super(initial_size, _)
        @recipient_pos = recipient_pos
      end

      def recipient
        @nodes[@recipient_pos]
      end

      def recipient=(node)
        @nodes[@recipient_pos] = node
      end
    end

    class CondRecipientClauseNode < RecipientClauseBaseNode
      def initialize(_ = nil)
        # <cond clause> -> ( <test> => <recipient> )
        # @nodes = [<test>, <recipient>]
        super(2, 1, _)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end
    end

    class ElseClauseNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # @nodes = [<sequence>]
        super(1, 0, _)
      end
    end

    class CaseNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<expression>, <case caluse>, ... <else clause>]
        super(1, _)
      end

      def expression
        @nodes[0]
      end

      def expression=(node)
        @nodes[0] = node
      end

      def case_clauses
        @nodes[1..-1]
      end

      def add_clause(node)
        @nodes << node
      end
    end

    class CaseClauseNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # @nodes = [<data>, <sequence>]
        super(2, 1, _)
      end

      def data
        @nodes[0]
      end

      def data=(node)
        @nodes[0] = node
      end
    end

    class DataNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<datum>, ...]
        super(0, _)
      end
    end

    class CaseRecipientClauseNode < RecipientClauseBaseNode
      def initialize(_ = nil)
        # ( ( <datum>* ) => <recipient> )
        # @nodes = [<data>, <recipient>]
        super(2, 1, _)
      end

      def data
        @nodes[0]
      end

      def data=(node)
        @nodes[0] = node
      end
    end

    class ElseRecipientClauseNode < RecipientClauseBaseNode
      def initialize(_ = nil)
        # ( else => <recipient> )
        # @nodes = [<recipient>]
        super(1, 0, _)
      end
    end

    class AndNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, ...]
        super(0, _)
      end
    end

    class OrNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<test>, ...]
        super(0, _)
      end
    end

    class TestAndSequenceBaseNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # @nodes = [<test>, <sequence>]
        super(2, 1, _)
      end

      def test
        @nodes[0]
      end

      def test=(node)
        @nodes[0] = node
      end
    end

    class WhenNode < TestAndSequenceBaseNode
    end

    class UnlessNode < TestAndSequenceBaseNode
    end

    class LetNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<bindings>, <body>] or
        #          [<identifier>, <bindings>, <body>]
        super(1, _)
      end

      def identifier
        named_let? ? @nodes[0] : nil
      end

      def identifier=(node)
        @nodes.insert(0, node) if node.type == :ast_identifier
      end

      def bindings
        named_let? ? @nodes[1] : @nodes[0]
      end

      def bindings=(node)
        if named_let?
          @nodes[1] = node
        else
          @nodes[0] = node
        end
      end

      def body
        named_let? ? @nodes[2] : @nodes[1]
      end

      def body=(node)
        start_pos = named_let? ? 2 : 1
        @nodes[start_pos] = node
      end

      private

      def named_let?
        @nodes[0].nil? ? false : @nodes[0].type == :ast_identifier
      end
    end

    class LetBaseNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<bindings>, <body>]
        super(2, _)
      end

      def bindings
        @nodes[0]
      end

      def bindings=(node)
        @nodes[0] = node
      end

      def body
        @nodes[1]
      end

      def body=(node)
        @nodes[1] = node
      end
    end

    class LetStarNode < LetBaseNode
    end

    class LetrecNode < LetBaseNode
    end

    class LetrecStarNode < LetBaseNode
    end

    class BindingsNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<bind spec 1>, <bind spec 2> , ...]
        super(0, _)
      end

      def add_bind_spec(node)
        @nodes << node
      end
    end

    class BindSpecNode < ListNode
      def initialize(_ = nil)
        super(2, _)
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

    class BeginNode < HoldingSequenceBaseNode
      def initialize(_ = nil)
        # @nodes = [<sequnece>]
        super(1, 0, _)
      end
    end

    class DoNode < ListNode
      def initialize(_ = nil)
        # @nodes = [<iteration bindings>, <test and do result>, <command>, ...]
        super(2, _)
      end

      def iteration_bindings
        @nodes[0]
      end

      def iteration_bindings=(node)
        @nodes[0] = node
      end

      def test_and_do_result
        @nodes[1]
      end

      def test_and_do_result=(node)
        @nodes[1] = node
      end

      def commands
        @nodes[2..-1]
      end

      def add_command(node)
        @nodes << node
      end
    end

    class IterationBindingsNode < ListNode
      def initialize(_ = nil)
        super(0, _)
      end

      def add_iteration_spec(node)
        @nodes << node
      end
    end

    class TestAndDoResultNode < TestAndSequenceBaseNode
    end

    class IterationSpecNode < ListNode
      def initialize(_ = nil)
        # 1. @nodes = [<identifier>, <init>, <step>]
        # 2. @nodes = [<identifier>, <init>]
        super(2, _)
      end

      def identifier
        @nodes[0]
      end

      def identifier=(node)
        @nodes[0] = node
      end

      def init
        @nodes[1]
      end

      def init=(node)
        @nodes[1] = node
      end

      def step
        @nodes[2]
      end

      def step=(node)
        @nodes[2] = node
      end
    end

  end                           # end of AST

end
