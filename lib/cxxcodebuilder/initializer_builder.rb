# encoding: utf-8

module CxxCodeBuilder
  # Builds array and struct initialization syntaxes.
  class InitializerBuilder
    def initialize(builder, start_character, end_character)
      @builder = builder
      @start_character = start_character
      @end_character = end_character
      @elements = []
    end

    def element(code)
      @elements << code
    end

    def string(str)
      element(str.inspect)
    end

    def array_initializer(&block)
      subbuilder = InitializerBuilder.new(@builder, '[', ']')
      subbuilder.instance_eval(&block)
      @elements << subbuilder
    end

    def struct_initializer(&block)
      subbuilder = InitializerBuilder.new(@builder, '{', '}')
      subbuilder.instance_eval(&block)
      @elements << subbuilder
    end

    alias array_element array_initializer
    alias struct_element struct_initializer

    # @private
    def write_code_without_newline
      @builder.add_code(@start_character)
      @builder.indent do
        @elements.each_with_index do |elem, i|
          if elem.respond_to?(:write_code_without_newline)
            elem.write_code_without_newline
          else
            @builder.add_code_without_newline(elem)
          end

          if i != @elements.size - 1
            @builder.add_raw_code(',')
          end
          @builder.newline
        end
      end
      @builder.add_code_without_newline(@end_character)
    end
  end
end
