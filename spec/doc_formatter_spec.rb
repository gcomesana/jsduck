require "jsduck/doc_formatter"
require "jsduck/relations"

describe JsDuck::DocFormatter do

  before do
    @formatter = JsDuck::DocFormatter.new
    @formatter.class_context = "Context"
    @formatter.relations = JsDuck::Relations.new([
      JsDuck::Class.new({
        :name => "Context",
        :members => {
          :method => [{:name => "bar", :tagname => :method}]
        },
        :statics => {
          :method => [{:name => "id", :tagname => :method}],
        },
      }),
      JsDuck::Class.new({
        :name => 'Ext.Msg'
      }),
      JsDuck::Class.new({
        :name => "Foo",
        :members => {
          :cfg => [{:name => "bar", :tagname => :cfg}],
        },
        :statics => {
          :method => [{:name => "id", :tagname => :method}],
        },
        :alternateClassNames => ["FooBar"]
      }),
    ])
  end

  describe "#replace" do

    # {@link ...}

    it "replaces {@link Ext.Msg} with link to class" do
      @formatter.replace("Look at {@link Ext.Msg}").should ==
        'Look at <a href="Ext.Msg">Ext.Msg</a>'
    end

    it "replaces {@link Foo#bar} with link to class member" do
      @formatter.replace("Look at {@link Foo#bar}").should ==
        'Look at <a href="Foo#cfg-bar">Foo.bar</a>'
    end

    it "replaces {@link Foo#id} with link to static class member" do
      @formatter.replace("Look at {@link Foo#id}").should ==
        'Look at <a href="Foo#method-id">Foo.id</a>'
    end

    it "uses context to replace {@link #bar} with link to class member" do
      @formatter.replace("Look at {@link #bar}").should ==
        'Look at <a href="Context#method-bar">bar</a>'
    end

    it "uses context to replace {@link #id} with link to static class member" do
      @formatter.replace("Look at {@link #id}").should ==
        'Look at <a href="Context#method-id">id</a>'
    end

    it "allows use of custom link text" do
      @formatter.replace("Look at {@link Foo link text}").should ==
        'Look at <a href="Foo">link text</a>'
    end

    it "Links alternate classname to real classname" do
      @formatter.replace("Look at {@link FooBar}").should ==
        'Look at <a href="Foo">FooBar</a>'
    end

    it "leaves text without {@link...} untouched" do
      @formatter.replace("Look at {@me here} too").should ==
        'Look at {@me here} too'
    end

    it "ignores unfinished {@link tag" do
      @formatter.replace("unfinished {@link tag here").should ==
        'unfinished {@link tag here'
    end

    it "handles {@link} spanning multiple lines" do
      @formatter.replace("Look at {@link\nExt.Msg\nsome text}").should ==
        'Look at <a href="Ext.Msg">some text</a>'
    end

    it "handles {@link} with label spanning multiple lines" do
      @formatter.replace("Look at {@link Ext.Msg some\ntext}").should ==
        "Look at <a href=\"Ext.Msg\">some\ntext</a>"
    end

    it "escapes link text" do
      @formatter.replace('{@link Ext.Msg <bla>}').should ==
        '<a href="Ext.Msg">&lt;bla&gt;</a>'
    end

    # {@img ...}

    it "replaces {@img some/image.png Alt text} with <img> element" do
      @formatter.replace("Look at {@img some/image.png Alt text}").should ==
        'Look at <img src="some/image.png" alt="Alt text"/>'
    end

    it "replaces {@img some/image.png} with <img> element with empty alt tag" do
      @formatter.replace("Look at {@img some/image.png}").should ==
        'Look at <img src="some/image.png" alt=""/>'
    end

    it "escapes image alt text" do
      @formatter.replace('{@img some/image.png foo"bar}').should ==
        '<img src="some/image.png" alt="foo&quot;bar"/>'
    end

    # auto-conversion of identifiable ClassNames to links
    describe "auto-detect" do
      before do
        @formatter.relations = JsDuck::Relations.new([
          JsDuck::Class.new({:name => 'FooBar'}),
          JsDuck::Class.new({:name => 'FooBar.Blah'}),
          JsDuck::Class.new({
            :name => 'Ext.form.Field',
            :members => {
              :method => [{:name => "getValues", :tagname => :method}]
            }
          }),
          JsDuck::Class.new({
            :name => 'Ext.XTemplate',
            :alternateClassNames => ['Ext.AltXTemplate']
          }),
          JsDuck::Class.new({:name => 'MyClass'}),
          JsDuck::Class.new({
            :name => 'Ext',
            :members => {
              :method => [{:name => "encode", :tagname => :method}]
            }
          }),
        ])
      end

      it "doesn't recognize John as class name" do
        @formatter.replace("John is lazy").should ==
          "John is lazy"
      end

      it "doesn't recognize Foo.Bar as class name" do
        @formatter.replace("Unknown Foo.Bar class").should ==
          "Unknown Foo.Bar class"
      end

      it "converts FooBar to class link" do
        @formatter.replace("Look at FooBar").should ==
          'Look at <a href="FooBar">FooBar</a>'
      end

      it "converts FooBar.Blah to class link" do
        @formatter.replace("Look at FooBar.Blah").should ==
          'Look at <a href="FooBar.Blah">FooBar.Blah</a>'
      end

      it "converts Ext.form.Field to class link" do
        @formatter.replace("Look at Ext.form.Field").should ==
          'Look at <a href="Ext.form.Field">Ext.form.Field</a>'
      end

      it "converts Ext.XTemplate to class link" do
        @formatter.replace("Look at Ext.XTemplate").should ==
          'Look at <a href="Ext.XTemplate">Ext.XTemplate</a>'
      end

      it "links alternate classname to canonical classname" do
        @formatter.replace("Look at Ext.AltXTemplate").should ==
          'Look at <a href="Ext.XTemplate">Ext.AltXTemplate</a>'
      end

      it "converts ClassName ending with dot to class link" do
        @formatter.replace("Look at MyClass.").should ==
          'Look at <a href="MyClass">MyClass</a>.'
      end

      it "converts ClassName ending with comma to class link" do
        @formatter.replace("Look at MyClass, it's great!").should ==
          'Look at <a href="MyClass">MyClass</a>, it\'s great!'
      end

      it "converts Ext#encode to method link" do
        @formatter.replace("Look at Ext#encode").should ==
          'Look at <a href="Ext#method-encode">Ext.encode</a>'
      end

      it "converts Ext.form.Field#getValues to method link" do
        @formatter.replace("Look at Ext.form.Field#getValues").should ==
          'Look at <a href="Ext.form.Field#method-getValues">Ext.form.Field.getValues</a>'
      end

      it "doesn't create links inside {@link} tag" do
        @formatter.replace("{@link MyClass a MyClass link}").should ==
          '<a href="MyClass">a MyClass link</a>'
      end

      it "doesn't create links inside {@img} tag" do
        @formatter.replace("{@img some/file.jpg a MyClass image}").should ==
          '<img src="some/file.jpg" alt="a MyClass image"/>'
      end
    end

    describe "with type information" do
      before do
        @formatter.relations = JsDuck::Relations.new([
          JsDuck::Class.new({
            :name => 'Foo',
            :members => {
              :method => [{:name => "select", :tagname => :method}],
              :event => [{:name => "select", :tagname => :event}],
            }
          })
        ])
      end

      it "replaces {@link Foo#method-select} with link to method" do
        @formatter.replace("Look at {@link Foo#method-select}").should ==
          'Look at <a href="Foo#method-select">Foo.select</a>'
      end

      it "replaces {@link Foo#event-select} with link to event" do
        @formatter.replace("Look at {@link Foo#event-select}").should ==
          'Look at <a href="Foo#event-select">Foo.select</a>'
      end
    end
  end

  describe "#format" do

    # Just a sanity check that Markdown formatting works
    it "converts Markdown to HTML" do
      @formatter.format("Hello **world**").should =~ /Hello <strong>world<\/strong>/
    end

    shared_examples_for "code blocks" do
      it "contains text before" do
        @html.should =~ /Some code/
      end

      it "contains the code" do
        @html.include?("if (condition) {\n    doSomething();\n}").should == true
      end

      it "does not create nested <pre> segments" do
        @html.should_not =~ /<pre>.*<pre>/m
      end
    end

    describe "<pre>" do
      before do
        @html = @formatter.format(<<-EOS.gsub(/^ *\|/, ""))
          |Some code<pre>
          |if (condition) {
          |    doSomething();
          |}
          |</pre>
        EOS
      end

      it_should_behave_like "code blocks"

      it "avoids newline after <pre>" do
        @html.should_not =~ /<pre>\n/m
      end
    end

    describe "<pre><code>" do
      before do
        @html = @formatter.format(<<-EOS.gsub(/^ *\|/, ""))
          |Some code<pre><code>
          |if (condition) {
          |    doSomething();
          |}
          |</code></pre>
        EOS
      end

      it_should_behave_like "code blocks"

      it "avoids newline after <pre><code>" do
        @html.should_not =~ /<pre><code>\n/m
      end
    end

  end

  describe "#shorten" do

    before do
      @formatter.max_length = 10
    end

    it "appends ellipsis to short text" do
      @formatter.shorten("Ha ha").should == "Ha ha ..."
    end

    it "shortens text longer than max length" do
      @formatter.shorten("12345678901").should == "1234567..."
    end

    it "strips HTML tags when shortening" do
      @formatter.shorten("<a href='some-long-link'>12345678901</a>").should == "1234567..."
    end

    it "takes only first centence" do
      @formatter.shorten("bla. blah").should == "bla. ..."
    end
  end

  describe "#too_long?" do

    before do
      @formatter.max_length = 10
    end

    it "is false when exactly equal to the max_length" do
      @formatter.too_long?("1234567890").should == false
    end

    it "is false when short sentence" do
      @formatter.too_long?("bla bla.").should == false
    end

    it "is true when long sentence" do
      @formatter.too_long?("bla bla bla.").should == true
    end

    it "ignores HTML tags when calculating text length" do
      @formatter.too_long?("<a href='some-long-link'>Foo</a>").should == false
    end

  end


  describe "#first_sentence" do
    it "extracts first sentence" do
      @formatter.first_sentence("Hi John. This is me.").should == "Hi John."
    end
    it "extracts first sentence of multiline text" do
      @formatter.first_sentence("Hi\nJohn.\nThis\nis\nme.").should == "Hi\nJohn."
    end
    it "returns everything if no dots in text" do
      @formatter.first_sentence("Hi John this is me").should == "Hi John this is me"
    end
    it "returns everything if no dots in text" do
      @formatter.first_sentence("Hi John this is me").should == "Hi John this is me"
    end
    it "ignores dots inside words" do
      @formatter.first_sentence("Hi John th.is is me").should == "Hi John th.is is me"
    end
    it "ignores first empty sentence" do
      @formatter.first_sentence(". Hi John. This is me.").should == ". Hi John."
    end
  end

end
