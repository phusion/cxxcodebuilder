#  Copyright (c) 2016 Phusion Holding B.V.
#
#  "Union Station" and "Passenger" are trademarks of Phusion Holding B.V.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

require_relative '../lib/cxxcodebuilder/builder'

module CxxCodeBuilder

describe Builder do
  it 'is initially empty' do
    expect(Builder.new.to_s).to eq('')
  end

  specify 'test indent' do
    builder = Builder.new do
      add_code 'foo();'
      indent do
        add_code 'bar();'
      end
    end

    expect(builder.to_s).to eq(
      "foo();\n" \
      "\tbar();\n"
    )
  end

  it 'changes two-space Ruby indenting into our own indenting' do
    builder = Builder.new do
      indent do
        add_code %q{
          if (true) {
            foo();
            if (true) {
              bar();
            }
          }
        }
      end
    end

    expect(builder.to_s).to eq(
      "\tif (true) {\n" \
      "\t\tfoo();\n" \
      "\t\tif (true) {\n" \
      "\t\t\tbar();\n" \
      "\t\t}\n" \
      "\t}\n"
    )
  end

  it 'preserves empty lines' do
    builder = Builder.new do
      add_code %q{
        hello();

        world();
      }
    end

    expect(builder.to_s).to eq(
      "hello();\n" \
      "\n" \
      "world();\n"
    )
  end

  specify 'test separator' do
    builder = Builder.new do
      add_code 'foo();'
      indent do
        add_code 'bar();'
        separator
        add_code 'baz();'
      end
    end

    expect(builder.to_s).to eq(
      "foo();\n" \
      "\tbar();\n" \
      "\n" \
      "\tbaz();\n"
    )
  end

  specify 'test includes' do
    builder = Builder.new do
      include '<stdio.h>'
    end

    expect(builder.to_s).to eq(
      "#include <stdio.h>\n"
    )
  end

  specify 'test defines' do
    builder = Builder.new do
      define 'HAVE_STDINT_H'
      define 'FOO bar'
      define 'TWO 1 + 2'
      define_string 'NAME', 'Joe Dalton'
    end

    expect(builder.to_s).to eq(
      "#define HAVE_STDINT_H\n" \
      "#define FOO bar\n" \
      "#define TWO 1 + 2\n" \
      "#define NAME \"Joe Dalton\"\n"
    )
  end

  specify 'test guard macros' do
    builder = Builder.new do
      guard_macros 'MY_HEADER_H' do
        field 'int foo'
      end
    end

    expect(builder.to_s).to eq(
      "#ifndef MY_HEADER_H\n" \
      "#define MY_HEADER_H\n" \
      "\n" \
      "int foo;\n" \
      "\n" \
      "#endif /* MY_HEADER_H */\n"
    )
  end

  specify 'test comments' do
    builder = Builder.new do
      comment %q{
        hello
        world
      }
    end

    expect(builder.to_s).to eq(
      "/*\n" \
      " * hello\n" \
      " * world\n" \
      " */\n"
    )
  end

  specify 'empty comment lines do not have trailing whitespaces' do
    builder = Builder.new do
      comment %q{
        hello

        world
      }
    end

    expect(builder.to_s).to eq(
      "/*\n" \
      " * hello\n" \
      " *\n" \
      " * world\n" \
      " */\n"
    )
  end

  specify 'Ruby two-line indenting are not converted to tabs' do
    builder = Builder.new do
      comment %q{
        hello
          world
      }
    end

    expect(builder.to_s).to eq(
      "/*\n" \
      " * hello\n" \
      " *   world\n" \
      " */\n"
    )
  end

  specify 'test structs' do
    builder = Builder.new do
      struct 'Foo' do
        member 'unsigned int bar'
      end
    end

    expect(builder.to_s).to eq(
      "struct Foo {\n" \
      "\tunsigned int bar;\n" \
      "};\n"
    )
  end

  specify 'test functions with string body' do
    builder = Builder.new do
      function('void hello(int a)', %q{
        int i = 1 + 2 + a + global;
        printf("hello world!\n");
      })
    end

    expect(builder.to_s).to eq(
      "void\n" \
      "hello(int a) {\n" \
      "\tint i = 1 + 2 + a + global;\n" \
      "\tprintf(\"hello world!\\n\");\n" \
      "}\n" \
      "\n"
    )
  end

  specify 'test functions with block body' do
    builder = Builder.new do
      function('void hello(int a)') do
        add_code 'int x = 1 + a;'
      end
    end

    expect(builder.to_s).to eq(
      "void\n" \
      "hello(int a) {\n" \
      "\tint x = 1 + a;\n" \
      "}\n" \
      "\n"
    )
  end

  it 'recognizes C++ namespaced functions' do
    builder = Builder.new do
      function('void Foo::bar()', '')
    end

    expect(builder.to_s).to eq(
      "void\n" \
      "Foo::bar() {\n" \
      "\n" \
      "}\n\n"
    )
  end

  it 'recognizes C++ const functions' do
    builder = Builder.new do
      function('void Foo::bar() const', '')
    end

    expect(builder.to_s).to eq(
      "void\n" \
      "Foo::bar() const {\n" \
      "\n" \
      "}\n\n"
    )
  end

  specify 'test C++ constructor member initializers' do
    builder = Builder.new do
      initializers = {
        'foo' => '1',
        'bar' => '2',
        'baz' => '"test"'
      }
      constructor('void Foo::Foo()', initializers, '')
    end

    expect(builder.to_s).to eq(
      "void\n" \
      "Foo::Foo()\n" \
      "\t: foo(1),\n" \
      "\t  bar(2),\n" \
      "\t  baz(\"test\")\n" \
      "{\n" \
      "\n" \
      "}\n\n"
    )
  end

  specify 'test fields' do
    builder = Builder.new do
      field 'static int a'
      field 'static int b', 123
      field 'static int c', '456'
      field 'static int d', str_val('hello world')
      field 'static int e' do
        array_initializer do
          element 1
          element 2
        end
      end
    end

    expect(builder.to_s).to eq(
      "static int a;\n" \
      "static int b = 123;\n" \
      "static int c = 456;\n" \
      "static int d = \"hello world\";\n" \
      "static int e = [\n" \
      "\t1,\n" \
      "\t2\n" \
      "];\n"
    )
  end

  specify 'test array initializers' do
    builder = Builder.new do
      array_initializer do
        element 1
        element 2
        element 3
        string_element "hello\tworld"
      end
    end

    expect(builder.to_s).to eq(
      "[\n" \
      "\t1,\n" \
      "\t2,\n" \
      "\t3,\n" \
      "\t\"hello\\tworld\"\n" \
      "]"
    )
  end

  specify 'test struct initializers' do
    builder = Builder.new do
      struct_initializer do
        element 1
        element 2
        string_element "hello\tworld"
        array_initializer_element do
          element 3
          element 4
        end
        element 5
      end
    end

    expect(builder.to_s).to eq(
      "{\n" \
      "\t1,\n" \
      "\t2,\n" \
      "\t\"hello\\tworld\",\n" \
      "\t[\n" \
      "\t\t3,\n" \
      "\t\t4\n" \
      "\t],\n" \
      "\t5\n" \
      "}"
    )
  end

  specify 'test multiple elements' do
    builder = Builder.new do
      field 'static int global'

      separator

      function('void hello(int a)', %q{
        abort();
      })
    end

    expect(builder.to_s).to eq(
      "static int global;\n" \
      "\n" \
      "void\n" \
      "hello(int a) {\n" \
      "\tabort();\n" \
      "}\n" \
      "\n"
    )
  end

  it 'allows customizing the indentation' do
    builder = Builder.new do
      set_indent_string '    '
      field 'int foo'
      indent do
        field 'int bar'
      end
    end

    expect(builder.to_s).to eq(
      "int foo;\n" \
      "    int bar;\n"
    )
  end
end

end
