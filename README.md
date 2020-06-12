# Aliyun::Log

阿里云简单日志服务(SLS) Ruby SDK Gem

### 目前支持的功能 API

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

### Model 映射

- 支持简单 Model 映射
- 类型显式 Cast 映射
- Scope 简单支持

### TODO

- [ ] 完善 Model 映射查询解析
- [ ] 优化 Model 映射创建数据
- [ ] 完善 restful 接口
- [ ] 完善 Model 逻辑结构

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

> ## SDK

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

# Or simple kv log
logstore.put_log({ key1: "value1", key2: "value2" })
logstore.put_log([
  { key1: "value1", key2: "value2" },
  { key1: "value11", key2: "value22" }
], time: Time.now.to_i)
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

> ## Model record

```ruby
Aliyun::Log.configure do |c|
  config.timestamps = false # turn off created_at field
  config.project = 'user_logs' # project name
end

# defind model class
class User
  include Aliyun::Log::Record

  # @param name: default using class name pluralize
  # @param field_index: toggle all field indecies
  # @param project: logstore project name
  # @param auto_sync: true or false, logstore automation create
  # @param field_doc_value: toggle all field analytic index, default true
  logstore name: 'users', field_index: true

  scope :children, -> { search('age <= 18') }

  scope :country , ->(name) { search("location: #{name}") }

  # @param 1: field name
  # @param type: text/long/double/json, default was text
  # @param cast_type: [:string, :integer, :bigdecimal, :json, :date, :datetime]
  # @param index: index toggle, higher than logstore.field_index
  # @param default: default value
  # @param doc_value: toggle analytic index, default true
  # @param caseSensitive: toggle word case sensitive, default false
  field :age, type: :long, index: false
  field :time, type: :text, cast_type: :datetime default: -> { Time.now }
  field :name, default: 'Dace'
  field :location, :text

  # ActiveModel::Validations
  validates :name, :what, presence: true

  # ActiveModel::Callbacks
  # support [initialize create save] callbacks
  before_save do
    self.location = name * 2
  end
end

# sync logstore and indecies
Aliyun::Log.init_logstore
```

#### filter methods

```ruby
User.from('2020-01-01') # log start time
User.to('2020-01-01 01:02:03') # log end time
User.limit(20) # default limit 100
User.page(30) # offset will set to 600
User.search('*').sql("SELECT name")
# Log Query: "*|SELECT name"
User.search(age: 18, location: 'beijing')
User.search("age = ? AND location = ?", 18, 'beijing')
# Log Query: "age: 18 and location: beijing|SELECT name"

# support chain responsibility
users = User.search('name: dace')
# pagination
users = users.page(1).limit(3).result
# result => [{"__source__"=>"", "__time__"=>"1591459200", "name"=>"dace"}]

# sql pagination
User.search('name: dace')
    .sql('SELECT name LIMIT 1,3')
    .result
# note:
# sql limit can't using with raw page() and limit()

# where using raw restful request
# https://help.aliyun.com/document_detail/29029.html
User.where(from: 0, to: Time.now.to_i, topic: 'topic3', line: 30).load
```

#### result functions

```ruby
User.count
User.from(Date.yesterday).sql('select * where name is not null').count
# => 100
User.result
# => [{"__source__"=>"", "__time__"=>"1590000000", "__topic__"=>"", "created_at"=>"2020-06-08T16:36:17+08:00", "name"=>"Dace", "age"=>"28", "time"=>"2020-06-08T16:36:17+08:00", "location"=>"DaceDace"}]
User.load
# => [#<User created_at: "2020-06-08T18:39:03+08:00", name: "Dace", age: "28", location: "DaceDace">]
User.first
User.first(3)
User.last
User.last(3)
User.second
User.third
User.fourth
User.fifth
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
