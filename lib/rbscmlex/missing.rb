# frozen_string_literal: true

module Rbscmlex

  # :stopdoc:
  EMSG = {
    unexpected_token_type: "unexpected token type: got=%s, expected=%s",
    missing_right_parenthesis: "missing right parenthesis",
  }
  # :startdoc:

  # Indicates a token is not expected one.
  class UnexpectedTokenTypeError < Error
    def initialize(got, expected = nil)
      super(EMSG[:unexpected_token_type] % [got, expected])
    end
  end

  # Indicates a mismatch of parenthesizes.
  class MissingRightParenthesisError < Error
    def initialize
      super(EMSG[:missing_right_parenthesis])
    end
  end

  class Lexer

    def skip_lparen(offset = 0)
      if peek_token(offset).type == :lparen
        skip_token(offset)
      else
        raise UnexpectedTokenTypeError.new(peek_token(offset).type, :lparen)
      end
    end

    def skip_rparen(offset = 0)
      if peek_token(offset).type == :rparen
        skip_token(offset)
      else
        raise MissingRightParenthesisError
      end
    end

  end

end
