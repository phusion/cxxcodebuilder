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

    def include(header_name)
      add_code("#include #{header_name}")
    end

    def comment(text)
      add_code '/*'
      prefix = "\t" * @indent_level
      prefix << ' * '
      @code << reindent(unindent(text.to_s), prefix)
      @code << "\n"
      add_code_without_newline '-'
      @code.gsub!(/-\Z/, ' ')
      add_raw_code "*/\n"
    end

    def struct(name)
      add_code "struct #{name} {"
      indent do
        yield
      end
      add_code '};'
    end

    def typedef_struct(name)
      add_code 'typedef struct {'
      indent do
        yield
      end
      add_code "} #{name};"
    end

    def function(declaration, body = nil)
      declaration =~ /(.*?)([a-z0-9_]+)[\s\t\n]*\((.*)/mi
      return_type_and_attributes = $1
      name_and_params = "#{$2}(#{$3}"

      add_code return_type_and_attributes.strip
      add_code "#{name_and_params.strip} {"
      indent do
        if block_given?
          yield
        else
          add_code body
        end
      end
      add_code '}'
      separator
    end

    def field(declaration, value = nil)
      if block_given?
        add_code_without_newline "#{declaration} ="
        add_raw_code ' '
        yield
        @code.gsub!(/\n*\Z/m, '')
        add_raw_code ';'
        newline
      elsif value
        add_code "#{declaration} = #{value};"
      else
        add_code "#{declaration};"
      end
    end

    alias variable field
    alias member field

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

    def str_val(str)
      str.to_s.inspect
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
