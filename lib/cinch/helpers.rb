module Cinch
  module Helpers
    # Helper method for turning a String into a {Channel} object.
    #
    # @param (see Bot#Channel)
    # @return (see Bot#Channel)
    # @example (see Bot#Channel)
    def Channel(*args)
      @bot.Channel(*args)
    end

    # Helper method for turning a String into an {User} object.
    #
    # @param (see Bot#User)
    # @return (see Bot#User)
    # @example (see Bot#User)
    def User(*args)
      @bot.User(*args)
    end
  end
end
