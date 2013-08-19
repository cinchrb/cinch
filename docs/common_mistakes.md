# @title Common mistakes
# @markup kramdown

# I defined an initialize method in my plugin and now it doesn't work properly anymore

Cinch requires plugins to set certain states for them to work
properly. This is done by the initialize method of the Plugin module.
If you define your own initializer, make sure to accept an arbitrary
number of arguments (`*args`) and to call `super` as soon as possible.

## Example

    class MyPlugin
      include Cinch::Plugin

      def initialize(*args)
        super
        my own stuff here
      end
    end


# I am trying to use plugin options, but Ruby says it cannot find the `config` method

A common mistake is to try and use plugin options on class level, for example to manipulate matches. This cannot work because the class itself is not connected to any bot. Plugin options only work in instance methods of plugins.

The following is not possible:

    class MyPlugin
      include Cinch::Plugin

      match(config[:pattern])
      def execute(m)
        # ...
      end
    end

# My handlers won't run, even though the Regexp matches.

Cinch plugins have a default prefix (`/^!/`). This allows for flexible prefixes
across the whole bot. The default prefix can be changed in `Bot#configure`:

    x = Cinch::Bot.new do
      configure do |c|
        # ...
        c.plugins.prefix = /^%/
      end
    end

Alternatively, you can set the prefix for specific plugins only, by calling `set`:

    class MyPlygin
      include Cinch::Plugin

      set :prefix, /^%/
    end

You can also choose to not use a prefix for specific matchers:

    match /hi/, use_prefix: false
