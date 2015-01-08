module Zabbirc
  class IdShortener
    CHAR_SET = ("A".."Z").to_a + (2..9).to_a.collect(&:to_s)

    IdTranslation = Struct.new(:id, :shorten_id, :used_at) do
      def touch
        self.used_at = Time.now
      end
    end

    def initialize max_cache_size=10_000, shorten_id_length = 3
      @max_cache_size = max_cache_size
      @shorten_id_length = shorten_id_length
      @mutex = Mutex.new
      @ids = {}
      @shorten_ids = {}
    end

    def get_id shorten_id
      @mutex.synchronize do
        translation = @shorten_ids[shorten_id.upcase]
        if translation
          translation.touch
          translation.id
        else
          nil
        end
      end
    end

    def get_shorten_id id
      @mutex.synchronize do
        translation = @ids[id]
        return translation.shorten_id if translation
        begin
          shorten_id = generate_shorten_id
        end while @shorten_ids.key?(shorten_id)
        translation = register_translation id, shorten_id
        translation.shorten_id.upcase
      end
    end

    def cache_size
      @ids.size
    end

    private

    def register_translation id, shorten_id
      cleanup_translations
      translation = IdTranslation.new(id, shorten_id, Time.now)
      @ids[id] = translation
      @shorten_ids[shorten_id] = translation
    end

    def generate_shorten_id
      shorten_id = ""
      @shorten_id_length.times do
        shorten_id << CHAR_SET[rand(CHAR_SET.size)]
      end
      shorten_id
    end

    def cleanup_translations
      return if cache_size < @max_cache_size
      translations_to_delete = Array.wrap(@ids.values.sort{|x,y| y.used_at <=> x.used_at }[@max_cache_size-1..-1])
      translations_to_delete.each do |translation|
        @ids.delete(translation.id)
        @shorten_ids.delete(translation.shorten_id)
      end
    end
  end
end