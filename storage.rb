# File storage with flock and caching
#
# Usage:
# Storage.new({
#   file_name:  'storage.txt',
#   cache_path: './cache/'
# }).write('Foo')

class Storage
  require 'securerandom'

  def initialize(options)
    file_name, @cache_path = options[:file_name], options[:cache_path]
    @storage = File.open( file_name, "a" )
    @locked  = @storage.flock( File::LOCK_EX | File::LOCK_NB )
  end

  def write(data)
    if ( @locked === false )
      # Locked
      puts_to_cache( data )
      # Raise for SideKiq execution
      raise 'Storage is locked. Making new cache'
    else
      # Unlocked
      write_from_cache()
      @storage << data
    end
  end

  protected

    def puts_to_cache(data)
      File.open( @cache_path + random_filename, "w" ) do |cache|
        cache.write( data )
      end
    end

    def random_filename
      SecureRandom.urlsafe_base64
    end

    def write_from_cache
      Dir.entries( @cache_path ).select do |fn|

        if ( !File.directory?( fn ) )
          cache_file = @cache_path + fn
          File.open( cache_file ) do |c|
            @storage << c.read
          end
          File.delete(cache_file)
        end

      end
    end
end