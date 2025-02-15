module AttributesAndTokenLists
  class AttributesBuilder
    class_attribute :tag_name, default: :div

    def self.define(name, tag_name: self.tag_name, **defaults, &block)
      if block.present?
        define_chainable_builder(name, tag_name, **defaults, &block)
      else
        define_builder(name, tag_name, **defaults)
      end
    end

    def self.define_chainable_builder(name, tag_name, **defaults, &block)
      builder_class = Class.new(self) do
        self.tag_name = tag_name

        block.arity.zero? ? instance_exec(&block) : yield_self(&block)
      end

      define_method name do
        builder_class.new(@view_context, **defaults)
      end
    end

    def self.define_builder(name, tag_name, **defaults)
      define_method name do
        @attributes.merge(defaults).as(tag_name)
      end
    end

    def initialize(view_context, **attributes)
      @view_context = view_context
      @attributes = view_context.tag.attributes(attributes)
    end

    def tag(...)
      @attributes.as(tag_name).tag(...)
    end

    def to_hash
      @attributes.to_hash
    end

    def to_h
      @attributes.to_h
    end

    def method_missing(name, *arguments, **options, &block)
      if @view_context.respond_to?(name)
        @view_context.public_send(name, *arguments, **@attributes.merge(options), &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @view_context.respond_to?(name)
    end
  end
end
