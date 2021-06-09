# frozen_string_literal: true

module Rubasteme
  VERSION = "0.1.6"
  RELEASE = "2021-06-09"

  def self.make_version(name)
    mod_name = name.downcase.split("::").join(".")
    "(#{mod_name} :version #{VERSION} :release #{RELEASE})"
  end
end
