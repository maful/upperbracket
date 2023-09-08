# frozen_string_literal: true

#
# Uncomment this and change the path if necessary to include your own
# components.
# See https://github.com/heartcombo/simple_form#custom-components to know
# more about custom components.
# Dir[Rails.root.join('lib/components/**/*.rb')].each { |f| require f }
#
# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers(:default, tag: :div, class: "form__item") do |b|
    b.use(:html5)
    b.use(:placeholder)
    b.optional(:pattern)
    b.optional(:readonly)
    b.use(:label, class: "label")
    b.use(:input, class: "input")
    b.use(:hint, wrap_with: { class: "description" })
    b.use(:full_error, wrap_with: { tag: :p, class: "message-destructive" })
  end

  config.default_wrapper = :default
  config.boolean_style = :inline
  config.button_class = nil
  config.error_method = :first
  config.error_notification_tag = :div
  config.error_notification_class = "error_notification"
  config.label_text = ->(label, _, _) { label }
  config.generate_additional_classes_for = []
  config.browser_validations = false
  config.boolean_label_class = "checkbox"
  config.include_default_input_wrapper_class = false
  config.wrapper_mappings = {}
end
