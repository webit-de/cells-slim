module Cell
  module Slim::Rails
    def self.included(includer)
      includer.send :include, ActionView::Helpers::FormHelper
      includer.send :include, ::Cell::Slim::Rails::Helpers
    end

    module Helpers # include after AV helpers to override.
      def with_output_buffer(block_buffer=ViewModel::OutputBuffer.new)
        @output_buffer, old_buffer = block_buffer, @output_buffer
        yield
        @output_buffer = old_buffer

        block_buffer
      end

      def capture(*args)
        value = nil
        buffer = with_output_buffer { value = yield(*args) }

        return buffer.to_s if buffer.size > 0
        value # this applies for "Beachparty" string-only statements.
      end

      # From FormTagHelper. why do they escape every possible string? why?
      def form_tag_in_block(html_options, &block)
        content = capture(&block)
        form_tag_with_body(html_options, content)
      end

      def form_tag_with_body(html_options, content)
        "#{form_tag_html(html_options)}" << content.to_s << "</form>"
      end

      def form_tag_html(html_options)
        extra_tags = extra_tags_for_form(html_options)
        "#{tag(:form, html_options, true) + extra_tags}"
      end

      def utf8_enforcer_tag
        super.to_str
      end

      class SafeBufferToStringWrapper < SimpleDelegator
        def self.ensure_string(something)
          # ActiveSupport::SafeBuffer is also a String
          if something.is_a?(String)
            something.to_str
          else
            # with rails 5 we could get a TagBuilder by using tag.div('foo'),
            # that we need to wrap to be sure to get a String in the end
            new(something)
          end
        end

        # calling a method on a tag builder should ensure it returns a plain String
        def method_missing(method, *args, &block)
          self.class.ensure_string(super)
        end
      end

      def tag(name = nil, options = nil, open = false, escape = true)
        SafeBufferToStringWrapper.ensure_string(super(name, options, open, false))
      end

      def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
        super(name, content_or_options_with_block, options, false, &block).to_str
      end

      def concat(string)
        @output_buffer << string
        self
      end
    end
  end
end
