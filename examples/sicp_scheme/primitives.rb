# frozen_string_literal: true

module SicpScheme

  # primitive procedure for SICP Scheme

  module Primitives
    def cons(obj1, obj2)
      [obj1, obj2]
    end

    def pair?(obj)
      obj.instance_of?(Array)
    end

    def car(lis)
      lis[0]
    end

    def cdr(lis)
      lis[1..-1]
    end

    def list(*args)
      args
    end

    def append(*args)
      if args.empty?
        []
      else
        args[0] + append(*args[1..-1])
      end
    end

    def write(obj)
      print obj
    end

    def display(obj)
      write(obj)
      print "\n"
    end

    def zero?(obj)
      eqv?(obj, 0)
    end

    def a_calc(op, *args)
      case args.size
      when 0
        0
      when 1
        args[0]
      else
        a_calc(op, args[0].send(op, args[1]), *args[2..-1])
      end
    end

    def add(*args)
      a_calc(:+, *args)
    end

    def subtract(*args)
      a_calc(:-, *args)
    end

    def mul(*args)
      a_calc(:*, *args)
    end

    def div(*args)
      a_calc(:/, *args)
    end

    def mod(*args)
      a_calc(:%, *args)
    end

    def scm_true
      [:ast_boolean, "#t"]
    end

    def scm_false
      [:ast_boolean, "#f"]
    end

    def c_calc(op, *args)
      case args.size
      when 0, 1
        raise ArgumentError, args.to_s
      when 2
        args[0].send(op, args[1]) ? scm_true : scm_false
      else
        args[0].send(op, args[1]) and c_calc(op, *args[1..-1]) ? scm_true : scm_false
      end
    end

    def lt?(*args)
      c_calc(:<, *args)
    end

    def le?(*args)
      c_calc(:<=, *args)
    end

    def gt?(*args)
      c_calc(:>, *args)
    end

    def ge?(*args)
      c_calc(:>=, *args)
    end

    def same_value?(*args)
      c_calc(:==, *args)
    end

    def eqv?(obj1, obj2)
      obj1 == obj2 ? scm_true : scm_false
    end
  end
end
