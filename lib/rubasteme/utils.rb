# frozen_string_literal: true

module Rubasteme
  module Utils
    def self.camel_case(snake_case)
      snake_case.to_s.split("_").map(&:capitalize).join("")
    end

    def self.snake_case(camel_case)
      camel_case.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end

  end
end
