shared_examples_for "Map CRDT" do
  let(:typed_collection){ Riak::Crdt::TypedCollection }

  it 'should contain counters' do
    expect(subject).to respond_to(:counters)
    expect(subject.counters).to be_an_instance_of typed_collection
  end
  
  it 'should contain flags' do
    expect(subject).to respond_to(:flags)
    expect(subject.counters).to be_an_instance_of typed_collection
  end
  
  it 'should contain maps' do
    expect(subject).to respond_to(:maps)
    expect(subject.counters).to be_an_instance_of typed_collection
  end
  
  it 'should contain registers' do
    expect(subject).to respond_to(:registers)
    expect(subject.counters).to be_an_instance_of typed_collection
  end
  
  it 'should contain sets' do
    expect(subject).to respond_to(:sets)
    expect(subject.counters).to be_an_instance_of typed_collection
  end

  it 'should accept operations' do
    expect(subject).to respond_to(:operate)
  end
end

shared_examples_for "Counter CRDT" do
  it 'should have a value' do
    expect(subject).to respond_to :value
  end
  
  it 'should have an increment method' do
    expect(subject).to respond_to :increment
  end

  it 'should have a decrement method' do
    expect(subject).to respond_to :decrement
  end

  it 'should have a batch method' do
    expect(subject).to respond_to :batch
  end
end

shared_examples_for 'Set CRDT' do
  it 'should have a value' do
    expect(subject).to respond_to :value
    expect(subject).to respond_to :members
    expect(subject).to respond_to :to_a
  end

  it 'should have an include? method' do
    expect(subject).to respond_to :include?
  end

  it 'should have an empty? method' do
    expect(subject).to respond_to :empty?
  end

  it 'should have an add method' do
    expect(subject).to respond_to :add
  end

  it 'should have a remove method' do
    expect(subject).to respond_to :remove
  end
end
