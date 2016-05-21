# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/initializer_builder')

module CxxCodeBuilder
  class Builder
    def initialize(&block)
      @indent_level = 0
      @code = ""

      if block
        instance_eval(&block)
      end
    end

    def add_code(code)
      add_code_without_newline(code)
      newline
    end

    def add_code_without_newline(code)
      @code << reindent(unindent(code.to_s), "\t" * @indent_level)
    end

    def add_raw_code(code)
      @code << code
    end

    def indent
      @indent_level += 1
      begin
        yield
      ensure
        @indent_level -= 1
      end
    end

    def separator
      add_code ''
    end

    def newline
      @code << "\n"
    end

    def function(return_type_and_attributes, name_and_params, body = nil)
      add_code return_type_and_attributes
      add_code "#{name_and_params} {"
      indent do
        if body
          add_code body
        else
          yield
        end
      end
      add_code '}'
      separator
    end

    def field(type_and_attributes, name)
      add_code "#{type_and_attributes} #{name};"
      separator
    end

    alias variable field

    def array_initializer(&block)
      subbuilder = InitializerBuilder.new(self, '[', ']')
      subbuilder.instance_eval(&block)
      subbuilder.write_code_without_newline
      newline
    end

    def struct_initializer(&block)
      subbuilder = InitializerBuilder.new(self, '{', '}')
      subbuilder.instance_eval(&block)
      subbuilder.write_code_without_newline
      newline
    end

    def to_s
      @code
    end

  private
    def unindent(str)
      str = str.dup
      str.gsub!(/\A([\s\t]*\n)+/, '')
      str.gsub!(/[\s\t\n]+\Z/, '')
      indent = str.split("\n").select{ |line| !line.strip.empty? }.map{ |line| line.index(/[^\s]/) }.compact.min || 0
      str.gsub!(/^[[:blank:]]{#{indent}}/, '')
      str
    end

    def reindent(str, indent_string)
      str = unindent(str)
      str.gsub!(/^/, indent_string)
      str
    end
  end
end
