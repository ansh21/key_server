require 'set'

class KeyServer
  attr_accessor :keys, :available_keys
  attr_reader :deleted_keys

  def initialize
    @keys = {}
    @available_keys = {}
    @deleted_keys = Set.new
    @mutex = Mutex.new
  end

  # Util function to generate a random key
  def random_key
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    (0...8).map { o[rand(o.length)] }.join
  end

  # Generate keys
  def generate_key(length)
    while @available_keys.size < length
      key = random_key
      next if @available_keys.key?(key) || @deleted_keys.include?(key)

      @mutex.synchronize do
        ts= Time.now.to_i
        @keys[key] = { :ct => ts, :st => ts}
        @available_keys[key] = true
      end
    end
    @available_keys.keys
  end

  # get an available key
  def get_key
    return nil if @available_keys.empty?
    key = -1
    @mutex.synchronize do
      key = @available_keys.shift[0]
      @keys[key][:ct] = Time.now.to_i
    end
    key
  end

  # unblocks the given key
  def unblock_key(key)
    return false unless @keys.key? key
    @mutex.synchronize do
      @keys[key][:ct] = @keys[key][:st]
      @available_keys[key] = true
    end
    true
  end

  # deletes the given key
  def delete_key(key)
    return false unless @keys.key? key
    @mutex.synchronize do
      @keys.delete(key)
      @available_keys.delete(key)
    end
    @deleted_keys.add key
    puts "Deleted Key: #{key}"
    true
  end

  # keep alive functionality for keys
  def keep_alive_key(key)
    return false unless @keys.key? key
    @mutex.synchronize do
      @keys[key][:st] = Time.now.to_i
      puts "Keep Alive called for Key: #{key}"
    end
    true
  end

  # Validate if the key expired in the given time
  def expired_kalive?(key, time)
    if !@keys.key?(key)
      return false
    end
    
    if Time.now.to_i - @keys[key][:st] > time
      puts "Expired key due to not received keepalive within #{time} seconds : #{key}"
      return true
    end

    false
  end

  def expired_unlocked?(key, time)
    if !@keys.key?(key) || @available_keys.key?(key)
      return false
    end

    if Time.now.to_i - @keys[key][:ct] > time
      puts "Expired key (condition of unblocked met) : #{key}"
      return true
    end

    false
  end

  #performs cleanup of the required keys
  def cleanup
    @keys.each { |key, time|
      if expired_kalive?(key, 300)
        delete_key(key)
      end

      if expired_unlocked?(key, 60)
        unblock_key(key)
      end
    }
    
  end

end
