describe Zabbirc::IdShortener do
  let(:cache_size) { 5 }
  let(:shorten_id_length) { 3 }
  let(:id_shortener) { Zabbirc::IdShortener.new(cache_size, shorten_id_length) }

  it "should generate shorten id" do
    shorten_id = id_shortener.get_shorten_id(1234)
    expect(shorten_id).to be_instance_of(String)
    expect(shorten_id.length).to eq(shorten_id_length)
  end

  let(:original_id) { 1234 }
  context "retrieving original id" do
    it "should retrieve original id" do
      shorten_id = id_shortener.get_shorten_id(original_id)
      id = id_shortener.get_id(shorten_id)
      expect(id).to eq(original_id)
    end

    it "should be case insensitive" do
      shorten_id = id_shortener.get_shorten_id(original_id)
      id = id_shortener.get_id(shorten_id.downcase)
      expect(id).to eq(original_id)
    end
  end


  it "should clean cache" do
    (cache_size*2).times do |i|
      id_shortener.get_shorten_id(i)
    end
    expect(id_shortener.cache_size).to be <= cache_size
    # ensures that cache is being cleand from the end (oldest used records)
    ids = id_shortener.instance_variable_get(:@ids).keys
    expect(ids).not_to include(1)
  end
end