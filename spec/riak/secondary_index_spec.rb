require 'spec_helper'

describe Riak::SecondaryIndex do
  before(:each) do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new @client, 'foo'
  end

  describe "initialization" do
    it "should accept a bucket, index name, and scalar" do
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa' }.should_not raise_error
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 12345 }.should_not raise_error
    end

    it "should accept a bucket, index name, and a range" do
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa'..'zzzz' }.should_not raise_error
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 1..5 }.should_not raise_error
    end
  end

  describe "operation" do
    before(:each) do
      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @args = [@bucket, 'asdf', 'aaaa'..'zzzz', {}]
      @index = Riak::SecondaryIndex.new *@args

      @backend.should_receive(:get_index).with(*@args).and_return(%w{abcd efgh})
    end

    it "should return an array of keys" do
      @results = @index.keys
      @results.should be_a Array
      @results.first.should be_a String
    end
    it "should return an array of values" do
      @backend.should_receive(:fetch_object).with(@bucket, 'abcd', {}).and_return('abcd')
      @backend.should_receive(:fetch_object).with(@bucket, 'efgh', {}).and_return('efgh')

      @results = @index.values
      @results.should be_a Array
      @results.length.should == 2
    end
  end

  describe "streaming" do
    it "should stream keys into a block" do
      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @args = [@bucket, 'asdf', 'aaaa'..'zzzz', {stream: true}]
      @index = Riak::SecondaryIndex.new *@args

      @backend.should_receive(:get_index).with(*@args).and_yield('abcd').and_yield('efgh')

      @index.keys {|b| :noop }
    end
  end

  describe "pagination" do
    it "should support max_results" do
      @max_results = 5

      @expected_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{aaaa bbbb cccc dddd eeee},
        'continuation' => 'examplecontinuation'
      }.to_json)

      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @backend.
        should_receive(:get_index).
        with(
             @bucket,
             'asdf',
             ('aaaa'..'zzzz'),
             :max_results => @max_results
             ).
        and_return(@expected_collection)
      @backend.stub(:get_server_version => '1.4.0')


      @index = Riak::SecondaryIndex.new(
                                        @bucket, 
                                        'asdf', 
                                        'aaaa'..'zzzz',
                                        :max_results => @max_results
                                        )

      @results = @index.keys
      @results.should be_an Array
      @results.should == @expected_collection
      @results.length.should == @max_results
    end

    it "should support continuations" do
      @max_results = 5

      @expected_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{ffff gggg hhhh}
      }.to_json)

      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @backend.
        should_receive(:get_index).
        with(
             @bucket,
             'asdf',
             ('aaaa'..'zzzz'),
             max_results: @max_results,
             continuation: 'examplecontinuation'
             ).
        and_return(@expected_collection)
      @backend.stub(:get_server_version => '1.4.0')


      @index = Riak::SecondaryIndex.new(
                                        @bucket, 
                                        'asdf', 
                                        'aaaa'..'zzzz',
                                        max_results: @max_results,
                                        continuation: 'examplecontinuation'
                                        )

      @results = @index.keys
      @results.should be_an Array
      @results.should == @expected_collection
    end

    it "should support a next_page method" do
      @max_results = 5

      @expected_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{aaaa bbbb cccc dddd eeee},
        'continuation' => 'examplecontinuation'
      }.to_json)

      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @backend.
        should_receive(:get_index).
        once.
        with(
             @bucket,
             'asdf',
             ('aaaa'..'zzzz'),
             :max_results => @max_results
             ).
        and_return(@expected_collection)
      @backend.stub(:get_server_version => '1.4.0')


      @index = Riak::SecondaryIndex.new(
                                        @bucket, 
                                        'asdf', 
                                        'aaaa'..'zzzz',
                                        :max_results => @max_results
                                        )

      @results = @index.keys
      @results.should == @expected_collection

      @second_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{ffff gggg hhhh}
      }.to_json)
      @backend.
        should_receive(:get_index).
        once.
        with(
             @bucket,
             'asdf',
             ('aaaa'..'zzzz'),
             max_results: @max_results,
             continuation: 'examplecontinuation'
             ).
        and_return(@second_collection)

      @second_page = @index.next_page
      @second_results = @second_page.keys
      @second_results.should == @second_collection
    end
  end

  describe "return_terms" do
    it "should optionally give the index value" do
      @expected_collection = Riak::IndexCollection.new_from_json({
        'results' => [
          {'aaaa' => 'aaaa'},
          {'bbbb' => 'bbbb'},
          {'bbbb' => 'bbbb2'}
        ]
        }.to_json)


      @backend = mock 'Backend'
      @client.stub!(:backend).and_yield(@backend)
      @backend.
        should_receive(:get_index).
        with(
             @bucket,
             'asdf',
             ('aaaa'..'zzzz'),
             :return_terms => true
             ).
        and_return(@expected_collection)
      @backend.stub(:get_server_version => '1.4.0')


      @index = Riak::SecondaryIndex.new(
                                        @bucket,
                                        'asdf',
                                        'aaaa'..'zzzz',
                                        :return_terms => true
                                        )

      @results = @index.keys
      @results.should be_an Array
      @results.should == @expected_collection
      @results.with_terms.should == {
        'aaaa' => %w{aaaa},
        'bbbb' => %w{bbbb bbbb2}
      }
    end
  end
end
