# Extensions to Ruby's Module class.
class Module
  # Like `attr_reader`, but for defining a synchronized attribute
  # reader.
  #
  # @api private
  def synced_attr_reader(attribute)
    undef_method(attribute)
    define_method(attribute) do
      attr(attribute)
    end

    define_method("#{attribute}_unsynced") do
      attr(attribute, false, true)
    end
  end

  # Like `attr_accessor`, but for defining a synchronized attribute
  # accessor
  #
  # @api private
  def synced_attr_accessor(attr)
    synced_attr_reader(attr)
    attr_accessor(attr)
  end
end
