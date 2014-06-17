require 'spec_helper'

describe Riak::SecondaryIndex do
  before(:each) do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new @client, 'foo'
  end

  describe "initialization" do
    it "should accept a bucket, index name, and scalar" do
      expect { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa' }.not_to raise_error
      expect { Riak::SecondaryIndex.new @bucket, 'asdf', 12345 }.not_to raise_error
    end

    it "should accept a bucket, index name, and a range" do
      expect { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa'..'zzzz' }.not_to raise_error
      expect { Riak::SecondaryIndex.new @bucket, 'asdf', 1..5 }.not_to raise_error
    end
  end

  describe "operation" do
    before(:each) do
      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      @args = [@bucket, 'asdf', 'aaaa'..'zzzz', {}]
      @index = Riak::SecondaryIndex.new *@args

      expect(@backend).to receive(:get_index).with(*@args).and_return(%w{abcd efgh})
    end

    it "should return an array of keys" do
      @results = @index.keys
      expect(@results).to be_a Array
      expect(@results.first).to be_a String
    end
    it "should return an array of values" do
      expect(@backend).to receive(:fetch_object).with(@bucket, 'abcd', {}).and_return('abcd')
      expect(@backend).to receive(:fetch_object).with(@bucket, 'efgh', {}).and_return('efgh')

      @results = @index.values
      expect(@results).to be_a Array
      expect(@results.length).to eq(2)
    end
  end

  describe "streaming" do
    it "should stream keys into a block" do
      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      @args = [@bucket, 'asdf', 'aaaa'..'zzzz', {stream: true}]
      @index = Riak::SecondaryIndex.new *@args

      expect(@backend).to receive(:get_index).with(*@args).and_yield('abcd').and_yield('efgh')

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

      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      expect(@backend).
        to receive(:get_index).
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
      expect(@results).to be_an Array
      expect(@results).to eq(@expected_collection)
      expect(@results.length).to eq(@max_results)
    end

    it "should support continuations" do
      @max_results = 5

      @expected_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{ffff gggg hhhh}
      }.to_json)

      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      expect(@backend).
        to receive(:get_index).
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
      expect(@results).to be_an Array
      expect(@results).to eq(@expected_collection)
    end

    it "should support a next_page method" do
      @max_results = 5

      @expected_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{aaaa bbbb cccc dddd eeee},
        'continuation' => 'examplecontinuation'
      }.to_json)

      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      expect(@backend).
        to receive(:get_index).
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
      expect(@results).to eq(@expected_collection)

      @second_collection = Riak::IndexCollection.new_from_json({
        'keys' => %w{ffff gggg hhhh}
      }.to_json)
      expect(@backend).
        to receive(:get_index).
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
      expect(@second_results).to eq(@second_collection)
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


      @backend = double 'Backend'
      allow(@client).to receive(:backend).and_yield(@backend)
      expect(@backend).
        to receive(:get_index).
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
      expect(@results).to be_an Array
      expect(@results).to eq(@expected_collection)
      expect(@results.with_terms).to eq({
        'aaaa' => %w{aaaa},
        'bbbb' => %w{bbbb bbbb2}
      })
    end
  end
end
