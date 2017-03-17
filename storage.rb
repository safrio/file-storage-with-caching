# File storage with flock and caching
#
# Usage:
# Storage.new({
#   file_name:  'storage.txt',
#   cache_path: './cache/'
# }).write('Foo')

require 'securerandom'
require 'pathname'

class Storage
  class LockedException < StandardError; end

  attr_reader :storage, :options, :locked

  def initialize(options)
    @options = options
    @storage = File.open(options.fetch(:file_name), "a")
    @locked  = storage.flock( File::LOCK_EX | File::LOCK_NB )
  end

  def write(data)
    if !locked
      # Locked
      puts_to_cache(data)
      # Raise for SideKiq execution
      raise LockedException, 'Storage is locked. Making new cache'
    else
      # Unlocked
      write_from_cache
      storage << data
    end
  end

  protected

  def puts_to_cache(data)
    path = Pathname.new(options.fetch(:cache_path)).join(random_filename)
    File.open(path, "w") do |cache|
      cache.write(data)
    end
  end

  def random_filename
    SecureRandom.urlsafe_base64
  end

  def write_from_cache
    Dir.entries(options.fetch(:cache_path)).select do |fn|
      if !File.directory?(fn)
        cache_file_path = Pathname.new(options.fetch(:cache_path)).join(fn)

        File.open(cache_file_path) do |c|
          storage << c.read
        end

        File.delete(cache_file_path)
      end
    end
  end
end