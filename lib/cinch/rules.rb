module Cinch

  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  #
  # == Description
  # Every rule defined through the Cinch::Base#plugin method becomes an instance 
  # of this class. Each rule consists of keys used for named parameters, a hash
  # of options, and an Array of callbacks. 
  #
  # When a rule matches an IRC message, all options with be checked, then all
  # callbacks will be invoked.
  class Rule < Struct.new(:rule, :keys, :options, :callbacks)
    def initialize(rule, keys, options, callback)
      callbacks = [callback]
      super(rule, keys, options, callbacks)
    end
  end

  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  #
  # == Description
  # This class provides an interface to manage rules. A rule should only ever be
  # added using the Rules#add_rule method and retrieved using the Rules#get_rule 
  # method, or an alias of these. 
  #
  # This class provides an easy way to add options or callbacks to an existing
  # rule.
  #
  # == Example
  #  rules = Cinch::Rules.new
  #
  #  rules.add('foo', [], {}, Proc.new{})
  #
  #  rules.add_callback('foo', Proc.new{})
  #  rules['foo'].callbacks #=> [#<Proc:0x9f1e110@(main):100>, #<Proc:0x9f1e0f4@(main):150>]
  #
  #  # Or assign directly
  #  rules.get('foo').callbacks << Proc.new {} 
  #
  #  rules['foo'].options #=> {}
  #  rules.add_option('foo', :nick, 'injekt')
  #  rules['foo'].options #=> {:nick => 'injekt'}
  #
  #  # Or retrieve the rule first and assign directly
  #  rules.get_rule('foo')
  #  rules.options = {:foo => 'bar'}
  #  rules.options[:bar] = 'baz'
  class Rules
    def initialize
      @rules = {}
    end

    # Add a new rule, overwrites an already existing rule
    def add_rule(rule, keys, options, callback)
      @rules[rule] = Rule.new(rule, keys, options, callback) 
    end
    alias :add :add_rule

    # Return a Cinch::Rule by its rule, or nil it one does not exist
    def get_rule(rule)
      @rules[rule]
    end
    alias :get :get_rule
    alias :[] :get_rule

    # Remove a rule
    def remove_rule(rule)
      @rules.delete(rule)
    end
    alias :remove :remove_rule

    # Check if a rule exists
    def include?(rule)
      @rules.key?(rule)
    end
    alias :has_rule? :include?

    # Add a callback for an already existing rule
    def add_callback(rule, blk)
      return unless include?(rule)
      @rules[rule].callbacks << blk
    end

    # Add an option for an already existing rule
    def add_option(rule, key, value)
      return unless include?(rule)
      @rules[rule].options[key] = value
    end

    # Remove all rules
    def clear
      @rules.clear
    end

    # Check if any rules exist
    def empty?
      @rules.empty?
    end

    # Return how many rules exist
    def count
      @rules.size
    end

    # Return the hash of rules
    def all
      @rules
    end

    # Return an Array of rules
    def to_a
      @rules.keys
    end
  end

end

