# frozen_string_literal: true

require "bundler/setup"
require "aliyun/log"
require "webmock/rspec"

module ClientSupport
  extend ActiveSupport::Concern

  included do
    let!(:project_name) { 'test-project' }
    let!(:logstore_name) { 'test-logstore' }
    let!(:client) do
      Aliyun::Log::Client.new(
        endpoint: Aliyun::Log.config.endpoint,
        access_key_id: 'key_id',
        access_key_secret: 'key_secret'
      )
    end

    let(:project) do
      project_name = 'test-project'
      stub_request(:get, request_path(project: project_name))
        .with(query: { projectName: project_name })
        .to_return(body: mock_project(project_name).to_json)
      client.get_project(project_name)
    end

    let(:get_logstore) do
      stub_request(:get, logstore_path(logstore_name))
        .with(query: { logstore_name: logstore_name })
        .to_return(body: mock_logstore(logstore_name).to_json)
      project.get_logstore(logstore_name)
    end

    def logstore_path(name = '', action = nil)
      request_path(project: project_name, logstore: name, action: action)
    end

    def mock_project(name)
      {
        "createTime" => "2020-06-06 23:33:39",
        "description" => "",
        "lastModifyTime" => "2020-06-08 23:33:39",
        "owner" => "iamironman",
        "projectName" => name,
        "region" => "cn-beijing",
        "status" => "Normal"
      }
    end

    def mock_logstore(name)
      {
        "logstoreName" => name,
        "ttl" => 365,
        "shardCount" => 2,
        "enable_tracking" => false,
        "autoSplit" => false,
        "maxSplitShard" => 0,
        "createTime" => 1591715194,
        "lastModifyTime" => 1594107418,
        "archiveSeconds" => 0,
        "appendMeta" => false,
        "productType" => "",
        "resourceQuota" => {
          "storage": {
            "preserved" => -1,
            "used" => 0
          }
        }
      }
    end

    def request_path(resource = {})
      Aliyun::Log::Utils.get_request_url(Aliyun::Log.config.endpoint, resource)
    end
  end
end

RSpec.configure do |config|
  config.include ClientSupport

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Aliyun::Log.configure.log_level = Logger::DEBUG
