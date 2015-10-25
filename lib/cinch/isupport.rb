module Cinch
  # This class exposes parsed ISUPPORT information of the IRC network.
  class ISupport < Hash
    @@mappings = {
      %w[PREFIX] => lambda {|v|
        modes, prefixes = v.match(/^\((.+)\)(.+)$/)[1..2]
        h = {}
        modes.split("").each_with_index do |c, i|
          h[c] = prefixes[i]
        end
        h
      },

      %w[CHANTYPES] => lambda {|v| v.split("")},
      %w[CHANMODES] => lambda {|v|
        h = {}
        h["A"], h["B"], h["C"], h["D"] = v.split(",").map {|l| l.split("")}
        h
      },

      %w[MODES MAXCHANNELS NICKLEN MAXBANS TOPICLEN
       KICKLEN CHANNELLEN CHIDLEN SILENCE AWAYLEN
       MAXTARGETS WATCH MONITOR] => lambda {|v| v.to_i},

      %w[CHANLIMIT MAXLIST IDCHAN] => lambda {|v|
        h = {}
        v.split(",").each do |pair|
          args, num = pair.split(":")
          args.split("").each do |arg|
            h[arg] = num.to_i
          end
        end
        h
      },

      %w[TARGMAX] => lambda {|v|
        h = {}
        v.split(",").each do |pair|
          name, value = pair.split(":")
          h[name] = value.to_i
        end
        h
      },

      %w[NETWORK] => lambda {|v| v},
      %w[STATUSMSG] => lambda {|v| v.split("")},
      %w[CASEMAPPING] => lambda {|v| v.to_sym},
      %w[ELIST] => lambda {|v| v.split("")},
      # TODO STD
    }

    def initialize(*args)
      super
      # by setting most numeric values to "Infinity", we let the
      # server truncate messages and lists while at the same time
      # allowing the use of strictness=:strict for servers that don't
      # support ISUPPORT (hopefully none, anyway)

      self["PREFIX"]    =  {"o" => "@", "v" => "+"}
      self["CHANTYPES"] =  ["#"]
      self["CHANMODES"] =  {
        "A"             => ["b"],
        "B"             => ["k"],
        "C"             => ["l"],
        "D"             => %w[i m n p s t r]
      }
      self["MODES"]       = 1
      self["NICKLEN"]     = Float::INFINITY
      self["MAXBANS"]     = Float::INFINITY
      self["TOPICLEN"]    = Float::INFINITY
      self["KICKLEN"]     = Float::INFINITY
      self["CHANNELLEN"]  = Float::INFINITY
      self["CHIDLEN"]     = 5
      self["AWAYLEN"]     = Float::INFINITY
      self["MAXTARGETS"]  = 1
      self["MAXCHANNELS"] = Float::INFINITY # deprecated
      self["CHANLIMIT"]   = {"#" => Float::INFINITY}
      self["STATUSMSG"]   = []
      self["CASEMAPPING"] = :rfc1459
      self["ELIST"]       = []
      self["MONITOR"]     = 0
    end

    # @api private
    # @return [void]
    def parse(*options)
      options.each do |option|
        name, value = option.split("=")
        if value
          proc = @@mappings.find {|key, _| key.include?(name)}
          self[name] = (proc && proc[1].call(value)) || value
        else
          self[name] = true
        end
      end
    end
  end
end
