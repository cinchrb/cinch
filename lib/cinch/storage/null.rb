require "cinch/storage"

module Cinch
  class Storage
    # The Null storage is the default storage (used if the user didn't
    # supply a different storage) and will simply ignore all requests.
    # This way, plugins will continue to work if programmed properly,
    # but no data will be preserved.
    class Null < Storage
    end
  end
end
