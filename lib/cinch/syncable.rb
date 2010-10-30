module Cinch
  module Syncable
    # Blocks until the object is synced.
    #
    # @return [void]
    # @api private
    def wait_until_synced(attr)
      attr = attr.to_sym
      while true
        return if @synced_attributes.include?(attr)
        sleep 0.1
      end
    end

    # @api private
    # @return [void]
    def sync(attribute, value, data = false)
      if data
        @data[attribute] = value
      else
        instance_variable_set("@#{attribute}", value)
      end
      @synced_attributes << attribute
    end

    # @return [Boolean]
    # @api private
    def synced?(attribute)
      @synced_attributes.include?(attribute)
    end

    # @return [void]
    # @api private
    def unsync(attribute)
      @synced_attributes.delete(attribute)
    end

    # @return [void]
    # @api private
    # @since 1.0.1
    def unsync_all
      @synced_attributes.clear
    end

    # @api private
    def attr(attribute, data = false, unsync = false)
      unless unsync
        if @when_requesting_synced_attribute
          @when_requesting_synced_attribute.call(attribute)
        end
        wait_until_synced(attribute)
      end

      if data
        return @data[attribute]
      else
        return instance_variable_get("@#{attribute}")
      end
    end

    # @api private
    # @return [void]
    def mark_as_synced(attribute)
      @synced_attributes << attribute
    end
  end
end
