class Module
  # @api private
  def synced_attr_reader(attribute)
    define_method(attribute) do
      attr(attribute)
    end

    define_method("#{attribute}_unsynced") do
      attr(attribute, false, true)
    end
  end

  # @api private
  def synced_attr_accessor(attr)
    synced_attr_reader(attr)
    attr_accessor(attr)
  end
end
