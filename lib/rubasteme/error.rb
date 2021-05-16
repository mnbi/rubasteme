# frozen_string_literal: true

module Rubasteme
  class Error < StandardError; end

  # :stopdoc:
  EMSG = {
    scheme_sytanx_error: "syntax error: got=%s",
    unexpected_token_type: "unexpected token type: got=%s, expected=%s",
    missing_right_parenthesis: "missing right parenthesis",
    unsupported_feature: "unsupported feature: %s",
    not_implemented_yet: "not implemented yet: %s",
  }
  # :startdoc:

  # Indicates a syntax error as Scheme program.
  class SchemeSyntaxErrorError < Error
    def initialize(literal)
      super(EMSG[:scheme_syntax_error] % literal)
    end
  end

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

  # Indicates a feature is not supported in Rubasteme.
  class UnsupportedFeatureError < Error
    def initialize(feature)
      super(EMSG[:unsupported_feature] % feature)
    end
  end

  # Indicates a feature is not implemented in the current release .
  class NotImplementedYetError < Error
    def initialize(feature)
      super(EMSG[:not_implemented_yet] % feature)
    end
  end
end
