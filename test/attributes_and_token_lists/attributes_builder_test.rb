require "test_helper"
require "capybara/minitest"

class AttributesAndTokenLists::AttributesBuilderTest < ActionView::TestCase
  include Capybara::Minitest::Assertions

  test "AttributesAndTokenLists.define declares helper" do
    define_builder_helper_method :test_builder
    define_builder_helper_method :another_builder

    assert view.respond_to?(:test_builder), "declares helper methods"
    assert view.respond_to?(:another_builder), "declares helper methods"
  end

  test "definitions yield the builder as an argument" do
    define_builder_helper_method :builder do |instance|
      instance.define :rounded, class: "rounded-full"
    end

    render inline: <<~ERB
      <%= builder.rounded.tag "Content" %>
    ERB

    assert_css "div", class: "rounded-full", text: "Content"
  end

  test "definitions can omit the builder argument from the block" do
    define_builder_helper_method :builder do
      define :rounded, class: "rounded-full"
    end

    render inline: <<~ERB
      <%= builder.rounded.tag "Content" %>
    ERB

    assert_css "div", class: "rounded-full", text: "Content"
  end

  test "definitions can declare a default tag with the tag_name: option" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button, class: "rounded-full"
    end

    render inline: <<~ERB
      <%= builder.button.tag "Submit" %>
      <%= builder.button.button_tag "Submit" %>
    ERB

    assert_button "Submit", class: "rounded-full", count: 2
  end

  test "definitions can define other variants" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button, class: "rounded-full" do
        define :primary, class: "bg-green-500"
      end
    end

    render inline: <<~ERB
      <%= builder.button.tag "Base" %>
      <%= builder.button.primary.tag "Primary" %>
      <%= builder.button.primary.button_tag "Primary" %>
    ERB

    assert_button "Base", class: %w[rounded-full]
    assert_button "Primary", class: %w[rounded-full bg-green-500], count: 2
  end

  test "defined attributes can render with content" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button
    end

    render inline: <<~ERB
      <%= builder.button.tag "Submit" %>
    ERB

    assert_button "Submit"
  end

  test "defined attributes can render without content" do
    define_builder_helper_method :builder do
      define :submit, tag_name: :input, type: "submit"
    end

    render inline: <<~ERB
      <%= builder.submit.tag %>
    ERB

    assert_button type: "submit"
  end

  test "defined attributes can render with overrides" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button, type: "submit"
    end

    render inline: <<~ERB
      <%= builder.button.tag "Submit" %>
      <%= builder.button.tag "Reset", type: "reset" %>
    ERB

    assert_button "Submit", type: "submit"
    assert_button "Reset", type: "reset"
  end

  test "defined attributes can render as other tags" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button, class: "rounded-full"
    end

    render inline: <<~ERB
      <%= builder.button.tag "A button" %>
      <%= builder.button.tag.input value: "An input", type: "button" %>
      <%= builder.button.tag.a "A link", href: "#" %>
    ERB

    assert_button "A button", class: "rounded-full"
    assert_field with: "An input", class: "rounded-full", type: "button"
    assert_link "A link", class: "rounded-full", href: "#"
  end

  test "defined attributes splat into Action View helpers" do
    define_builder_helper_method :builder do
      define :button, tag_name: :button, class: "rounded-full"
    end

    render inline: <<~ERB
      <%= form_with scope: :post, url: "/" do |form| %>
        <%= form.button "Submit", builder.button.(class: "btn") %>
      <% end %>
    ERB

    assert_css "form" do
      assert_button "Submit", class: %w[rounded-full btn], type: "submit"
    end
  end

  def page
    @page ||= Capybara.string(rendered)
  end

  def define_builder_helper_method(name, &block)
    AttributesAndTokenLists.define(name, &block)
    view.extend(AttributesAndTokenLists.define_builder_helper_methods(Module.new))
  end
end
