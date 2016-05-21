require_relative '../lib/csyntax-builder/builder'

module CSyntaxBuilder

describe Builder do
  it 'is initially empty' do
    expect(Builder.new.to_s).to eq('')
  end

  specify 'test functions with string body' do
    builder = Builder.new do
      function('void', 'hello(int a)', %q{
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
      function('void', 'hello(int a)') do
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

  specify 'test fields' do
    builder = Builder.new do
      field 'static int', 'global'
    end

    expect(builder.to_s).to eq(
      "static int global;\n" \
      "\n"
    )
  end

  specify 'test array initializers' do
    builder = Builder.new do
      array_initializer do
        element 1
        element 2
        element 3
        string "hello\tworld"
      end
    end

    expect(builder.to_s).to eq(
      "[\n" \
      "\t1,\n" \
      "\t2,\n" \
      "\t3,\n" \
      "\t\"hello\\tworld\"\n" \
      "]\n"
    )
  end

  specify 'test struct initializers' do
    builder = Builder.new do
      struct_initializer do
        element 1
        element 2
        string "hello\tworld"
        array_initializer do
          element 3
          element 4
        end
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
      "\t]\n" \
      "}\n"
    )
  end

  specify 'test multiple elements' do
    builder = Builder.new do
      field 'static int', 'global'

      function('void', 'hello(int a)', %q{
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
end

end
