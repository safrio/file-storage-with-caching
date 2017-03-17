# File storage with flock and caching

Usage:
```ruby
Storage.new({
  file_name:  'storage.txt',
  cache_path: './cache/'
}).write('Foo')
```