# frozen_string_literal: true

module SicpScheme

  # An evaluator which can evaluate the subset of syntax and procedures
  # of Scheme language.  It is derived from SICP Chatpter 4.

  class Evaluator
    include Primitives

    def version                   # :nodoc:
      ver = "0.1.0"
      rel = "2021-05-20"
      "(SICP-evaluator :version #{ver} :release #{rel})"
    end

    def initialize
      @ver = version
    end

    def eval(exp, env)
      case tag(exp)
      when :ast_program
        result = nil
        cdr(exp).each { |node|
          result = self.eval(node, env)
        }
        result
      when :ast_empty_list
        []
      when :ast_boolean
        eval_boolean(exp, env)
      when *EV_SELF_EVALUATING
        eval_self_evaluating(exp, env)
      when *EV_VARIABLE
        lookup_variable_value(exp[1], env)
      when *EV_QUOTED
        text_of_quotation(exp)
      when *EV_ASSIGNMENT
        eval_assignment(exp, env)
      when *EV_DEFINITION
        eval_definition(exp, env)
      when *EV_IF
        eval_if(exp, env)
      when *EV_LAMBDA
        internal_definitions(exp).each { |d|
          eval_definition(d, env)
        }
        make_procedure(lambda_parameters(exp),
                       lambda_body(exp),
                       env)
      when *EV_BEGIN
        eval_sequence(begin_actions(exp), env)
      when *EV_COND
        eval_if(cond_to_if(exp), env)
      when *EV_APPLICATION
        apply(self.eval(operator(exp), env),
              list_of_values(operands(exp), env))
      else
        raise Error, "Unknown expression type -- EVAL: got=%s" % tag(exp)
      end
    end

    def apply(procedure, arguments)
      if primitive_procedure?(procedure)
        apply_primitive_procedure(procedure, arguments)
      elsif compound_procedure?(procedure)
        apply_compound_procedure(procedure, arguments)
      else
        raise Error, "Unknown procedure type -- APPLY: got=%s" % procedure.to_s
      end
    end

    private

    def empty_env
      Kernel.binding
    end

    EV_SELF_EVALUATING = [:ast_string, :ast_number,]
    EV_VARIABLE        = [:ast_identifier]
    EV_QUOTED          = [:ast_quotation]
    EV_ASSIGNMENT      = [:ast_assignment]
    EV_DEFINITION      = [:ast_identifier_definition]
    EV_IF              = [:ast_conditional]
    EV_LAMBDA          = [:ast_lambda_expression]
    EV_BEGIN           = [:ast_begin]
    EV_COND            = [:ast_cond]
    EV_APPLICATION     = [:ast_procedure_call]

    def tagged?(exp)
      exp.instance_of?(Array) and exp.size > 1 and exp[0].instance_of?(Symbol)
    end

    def tag(exp)
      exp[0] if tagged?(exp)
    end

    def package(exp)
      exp[1..-1] if tagged?(exp)
    end

    def identifier(exp)
      if tagged?(exp) and tag(exp) == :ast_identifier
        exp[1]
      end
    end

    def lookup_variable_value(var, env)
      val = env.lookup_variable_value(var)
      if val.nil?
        rb_name = scm2rb_name(var).intern
        val = method(rb_name) if respond_to?(rb_name)
      end
      raise Error, "Unbound variable: got=%s" % var if val.nil?
      val
    end

    SCM2RB_OPS_MAP = {
      "+" => "add",
      "-" => "subtract",
      "*" => "mul",
      "/" => "div",
      "%" => "mod",
      "=" => "eqv?",
      "<" => "lt?",
      ">" => "gt?",
      "<=" => "le?",
      ">=" => "ge?",
    }

    def scm2rb_name(scm_name)
      scm_name.sub(/\A([+\-\*\/%=])|([<>]=?)\Z/, SCM2RB_OPS_MAP)
    end

    def eval_self_evaluating(exp, env)
      case tag(exp)
      when :ast_number
        case exp[1]
        when /([^\/]+)\/([^\/]+)/
          md = Regexp.last_match
          Kernel.eval("Rational(md[1], md[2])")
        else
          Kernel.eval(exp[1])
        end
      else
        Kernel.eval(exp[1])
      end
    end

    def eval_assignment(exp, env)
      # exp = [:ast_assignment, [:ast_identifier], [:ast_*]]
      var = assignment_variable(exp)
      val = self.eval(assignment_value(exp), env)
      env.set_variable(var, val)
      val
    end

    def assignment_variable(exp)
      # exp[1] = [:ast_identifier, <literal>]
      exp[1][1]
    end

    def assignment_value(exp)
      exp[2]
    end

    def operator(exp)
      # exp = [:ast_procedure_call, [:ast_*_1], [:ast_*_2], [:ast_*_3], ...]
      # :ast_*_1 must be :ast_identifier or :ast_lambda_expression
      exp[1]
    end

    def operands(exp)
      # exp = [:ast_procedure_call, [:ast_*_1], [:ast_*_2], [:ast_*_3], ...]
      exp[2..-1]
    end

    def list_of_values(exps, env)
      exps.map{|e| self.eval(e, env)}
    end

    def primitive_procedure?(procedure)
      procedure.instance_of?(Method)
    end

    def compound_procedure?(procedure)
      tagged?(procedure) and tag(procedure) == :sicp_scheme_procedure
    end

    def apply_primitive_procedure(procedure, arguments)
      if procedure.instance_of?(Method)
        procedure.call(*arguments)
      end
    end

    def apply_compound_procedure(procedure, arguments)
      base_env = procedure_environment(procedure)
      extended_env = base_env.extend(procedure_parameters(procedure),
                                     arguments)
      eval_sequence(procedure_body(procedure), extended_env)
    end

    def begin_actions(exp)
      # exp = [:ast_begin, [:ast_sequence]]
      # sequence = [:ast_sequence, [:ast_*_1], [:ast_*_2], ...]
      exp[1][1..-1]
    end

    def eval_sequence(exps, env)
      if last_exp?(exps)
        self.eval(first_exp(exps), env)
      else
        self.eval(first_exp(exps), env)
        eval_sequence(rest_exps(exps), env)
      end
    end

    def last_exp?(exps)
      exps.instance_of?(Array) and exps.size == 1
    end

    def first_exp(exps)
      exps.instance_of?(Array) and exps[0]
    end

    def rest_exps(exps)
      exps.instance_of?(Array) and exps[1..-1]
    end

    def eval_definition(exp, env)
      var = definition_variable(exp)
      val = self.eval(definition_value(exp), env)
      env.define_variable(var, val)
      var
    end

    def definition_variable(exp)
      # exp = [:ast_identifier_definition, [:ast_identifier], [:ast_*]]
      identifier(exp[1])
    end

    def definition_value(exp)
      # exp = [:ast_identifier_definition, [:ast_identifier], [:ast_*]]
      exp[2]
    end

    def internal_definitions(exp)
      # exp = [:ast_lambda_expression, [:ast_formals], [:ast_body]]
      # body = [:ast_body, [:ast_internal_definitions], [:ast_sequence]]
      # internal_definitions = [:ast_intern_definitions, [:ast_definition], ...]
      exp[2][1][1..-1]
    end

    def lambda_parameters(exp)
      # exp = [:ast_lambda_expression, [:ast_formals], [:ast_body]]
      formals = exp[1][1..-1]
      formals.map{|node| identifier(node)}
    end

    def lambda_body(exp)
      # exp = [:ast_lambda_expression, [:ast_formals], [:ast_body]]
      # body = [:ast_body, [:ast_internal_definitions], [:ast_sequence]]
      # sequence = [:ast_sequence, [:ast_*_1], [:ast_*_2], ...]
      exp[2][2][1..-1]
    end

    def make_procedure(parameters, body, env)
      # parameters = [:ast_formals, [:ast_identifier_1], [:ast_identifier_2] ...]
      # body = [[:ast_*_1], [:ast_*_2], ...]
      [:sicp_scheme_procedure, parameters, body, env]
    end

    def procedure_parameters(procedure)
      compound_procedure?(procedure) and procedure[1]
    end

    def procedure_body(procedure)
      compound_procedure?(procedure) and procedure[2]
    end

    def procedure_environment(procedure)
      compound_procedure?(procedure) and procedure[3]
    end

    def eval_if(exp, env)
      if true?(self.eval(if_predicate(exp), env))
        self.eval(if_consequent(exp), env)
      else
        self.eval(if_alternative(exp), env)
      end
    end

    def if_predicate(exp)
      # exp = [:ast_conditional, [:ast_*], [:ast_*],  [:ast_*]]
      #                          predicate consequent alternative
      exp[1]
    end

    def if_consequent(exp)
      exp[2]
    end

    def if_alternative(exp)
      exp[3]
    end

    def true?(exp)
      self.eval_boolean(exp, nil)
    end

    def eval_boolean(exp, _ = nil)
      case exp[1]
      when /\A#f(alse)?\Z/
        false
      when /\A#t(rue)?\Z/
        true
      else
        raise Error, "Invalid boolean literal -- EVAL: got=%s" % exp[1]
      end
    end

  end

end
