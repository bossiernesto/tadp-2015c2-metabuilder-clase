class Metabuilder
  attr_reader :klass, :properties, :validations

  def initialize
    @validations = []
    @properties = []
  end

  def set_class(klass)
    @klass = klass
  end

  def create_class(sym, &block)
    @klass = Class.new
    Object.const_set sym, @klass
    @klass.instance_eval &block
  end

  def set_properties(*args)
    @properties += args
  end

  def validate(&block)
    @validations << block
  end

  def build
    Builder.new @klass, @properties, @validations
  end

end

class Builder
  attr_reader :properties, :validations

  def initialize(klass, properties, validations)
    @klass = klass
    @properties= {}
    @validations = validations
    properties.each do |property|
      self.properties[property] = nil
    end
  end

  def set_property(sym, value)
    self.properties[sym] = value
  end

  def method_missing(symbol, *args)
    property_symbol = symbol.to_s[0..-2].to_sym
    super unless self.properties.has_key? property_symbol

    self.set_property property_symbol, args[0]
  end

  def respond_to_missing?(symbol, include_all)
    #Vos no sos mi jefe
    property_symbol = symbol.to_s[0..-2].to_sym
    self.properties.has_key? property_symbol
  end

  def build
    instancia = @klass.new
    self.properties.each do |property, value|
      instancia.send "#{property}=".to_sym, value
    end

    raise ValidationError unless @validations.all? do |validation|
      instancia.instance_eval &validation
    end
    instancia
  end
end


class ValidationError < StandardError

end