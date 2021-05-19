# frozen_string_literal: true

module SicpScheme

  class Environment
    def self.empty_environment
      Environment.new(nil)
    end

    def initialize(base_env = nil)
      @frame = nil
      @enclosing_environment = base_env
    end

    attr_reader :frame
    attr_reader :enclosing_environment

    def extend(vars, vals)
      if vars.size < vals.size
        raise Error, "Too many arguments supplied: %s => %s" % [vars, vals]
      elsif vars.size > vals.size
        raise Error, "Too few arguments supplied: %s => %s" % [vars, vals]
      else
        new_env = Environment.new(self)
        new_env.make_frame(vars, vals)
        new_env
      end
    end

    def lookup_variable_value(var)
      value, _ = lookup_value_and_env_defined_var(var)
      value
    end

    def define_variable(var, val)
      if @frame
        @frame[var] = val
      else
        @frame = make_frame([var], [val])
      end
      val
    end

    def set_variable(var, val)
      _, env = lookup_value_and_env_defined_var(var)
      if env
        env.frame[var] = val
      else
        raise Error, "Unbound variable: got=%s" % var
      end
    end

    def make_frame(variables, values)
      @frame = Frame.new(variables, values)
    end

    class Frame
      def initialize(variables, values)
        @bindings = variables.zip(values).to_h
      end

      def defined?(var)
        @bindings.key?(var)
      end

      def [](var)
        @bindings[var]
      end

      def []=(var, val)
        @bindings[var] = val
      end

      def variables
        @bindings.keys
      end

      def values
        @bindings.values
      end

      def add_binding(var, val)
        @bindings[var] = val
      end
    end

    private

    def lookup_value_and_env_defined_var(var)
      value = nil
      env = self
      while env
        if env.frame && env.frame.defined?(var)
          value = env.frame[var]
          break
        end
        env = env.enclosing_environment
      end
      [value, env]
    end

  end
end
