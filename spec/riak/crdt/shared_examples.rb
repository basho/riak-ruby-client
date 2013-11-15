shared_examples_for "Map CRDT" do
  it 'should contain counters' do
    expect(subject).to respond_to(:counters)
  end
  
  it 'should contain flags' do
    expect(subject).to respond_to(:flags)
  end
  
  it 'should contain maps' do
    expect(subject).to respond_to(:maps)
  end
  
  it 'should contain registers' do
    expect(subject).to respond_to(:registers)
  end
  
  it 'should contain sets' do
    expect(subject).to respond_to(:sets)
  end
end
