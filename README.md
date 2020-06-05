# Aliyun::Log

阿里云简单日志服务(SLS)Gem

### 目前支持的功能

#### 项目相关：

- 列表
- 创建
- 修改
- 删除

#### Logstore 相关：

- 列表
- 创建
- 修改
- 删除

#### 索引相关

- 查看
- 创建
- 修改
- 删除

#### 日志相关

- 查询
- 创建日志
- histograms

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aliyun-log'
```

Include the following in your project or 'irb' command:

```ruby
require 'aliyun/log'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aliyun-log

## Usage

### [optional] Global configure

```ruby
Aliyun::Log.configure do |config|
  config.access_key_id      = 'key_id'
  config.access_key_secret  = 'key_secret'
  config.endpoint  = 'https://cn-beijing.log.aliyuncs.com'
  config.log_file  = 'aliyun_log.log' # default
  # Logger::DEBUG | Logger::INFO | Logger::ERROR | Logger::FATAL
  config.log_level = Logger::DEBUG # default
end
```

In specific, the `endpoint` is the Log service address. The address may vary based on different regions for the node. The address for a Beijing node is: `https://cn-beijing.log.aliyuncs.com` by default configure. the `endpoint` also support for internal address just like normal address.

### Create a client

```ruby
client = Aliyun::Log::Client.new(
  endpoint: 'https://cn-beijing.log.aliyuncs.com',
  access_key_id: 'key_id',
  access_key_secret: 'key_secret'
)

# or using default global config
client = Aliyun::Log::Client.new
```

### List projects

```ruby
projects = client.list_projects # arguments(size = 500, offset = 0)
# => projects
{
  "count" => 0,
  "total" => 0,
  "projects" => [Aliyun::Log::Project#instance]
}
projects["projects"].each { |project| p project.name }

client.projects equal projects["projects"]
```

### Get project

```ruby
project = client.get_project('project_name')
# or
project = projects["projects"][0]
```

### Delete project

```ruby
client.delete_project('project_name')
```

### Update project

```ruby
client.update_project('project_name', 'project description')
```

### List logstores

```ruby
project.list_logstores # arguments(size = 500, offset = 0)
# =>
{
  "count"=>1,
  "logstores"=>["nginx_log"],
  "total"=>2
}
```

### Get logstore

```ruby
logstore = project.get_logstore('logstore_name')
logstore.name
```

### Logstore index

```ruby
logstore.get_index
logstore.create_index_line # only full text index
logstore.create_index(
  key1: {
    type: 'text',
  },
  key2: {
    type: 'long'
  }
)
logstore.update_index(
  key1: {
    type: 'text',
  },
  key2: {
    type: 'text'
  }
)
logstore.delete_index
```

### Put logs

```ruby
log = Aliyun::Log::Protobuf::Log.new(
  time: Time.now.to_i,
  contents: [{ key: "k1", value: "v1" }]
)
log_group = Aliyun::Log::Protobuf::LogGroup.new(
  logs: [log] # limit less than 4096 items and limit body less than 3mb
)
logstore.put_logs(log_group)

# Or simple single kv log
logstore.put_log({ key1: "value1", key2: "value2" })
```

### Get logs

```ruby
logstore.get_logs(from: Time.now.to_i - 3600, to: Time.now.to_i)
logstore.get_logs(
  from: Time.now.to_i - 3600,
  to: Time.now.to_i,
  query: "*|select count(*), 'k1' as kk", # 'full text search or sql'
  line: 100,
  offset: 0,
  reverse: false,
  topic: '' # __topic__
)
```

### Get log histograms

```ruby
logstore.get_histograms(
  from: Time.now.to_i - 3600,
  to: Time.now.to_i,
  query: "*|select count(*), 'k1' as kk",
)
```

## Logger

#### Log file in the directory of project root `aliyun_log.log` and level was `Logger::DEBUG` by default using global config.

#### logger and level

```ruby
Aliyun::Log::Common::Logging.logger = Logger.new('aliyun.log')
Aliyun::Log::Common::Logging.loger_file = 'aliyun.log'

# Logger::DEBUG | Logger::INFO | Logger::ERROR | Logger::FATAL
Aliyun::Log::Common::Logging.log_level = Logger::INFO
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yingce/aliyun-log. This project is intended to be a safe, welcoming space for collaboration

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Aliyun::Log project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yingce/aliyun-log/blob/master/CODE_OF_CONDUCT.md).
