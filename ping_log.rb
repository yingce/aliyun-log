# load 'ping_log.rb'

Aliyun::Log.configure do |c|
  c.access_key_id = ENV['ALIYUN_LOG_ACCESS_KEY_ID']
  c.access_key_secret = ENV['ALIYUN_LOG_ACCESS_KEY_SECRET']
  c.project = ENV['ALIYUN_LOG_PROJECT_NAME']
end

class PingLog
  include Aliyun::Log::Record

  logstore field_index: false

  field :sv, default: '0.1'
  field :ts, cast_type: :datetime
  field :date, cast_type: :date
  field :hour, type: :long, cast_type: :integer
  field :product
  field :wechat_v
  field :v
  field :parent
  field :span
  field :u
  field :uid
  field :obj
  field :params
  field :verb
  field :t
  field :sid
  field :submit_data, type: :json, cast_type: :json
  field :ipaddr
  field :user_agent
  field :province
  field :city
  field :device
  field :device_sig
  field :lang
  field :title
  field :sr
  field :referrer
  field :gt_ms, type: :long, cast_type: :integer
  field :req_ms, type: :long, cast_type: :integer
  field :x_request_id, type: :text

  scope :today, -> { from(Date.today.beginning_of_day).to(Date.today.end_of_day) }

  before_save :set_field

  def set_field
    self.ts ||= Time.now
    self.ts = self.ts.to_time.localtime
    # self.req_ms = (Time.now - self.ts.to_time).to_i
    self.date = self.ts.to_date
    self.hour = self.ts.hour
    self.t = (verb&.match(/(click|share|submit)/)&.[]1) || verb if t.blank?
    self.obj = nil if obj == '{}'
    span_splits = span.split(':')
    if span_splits.size == 2
      self.parent = span_splits[0] if span_splits[0] != '0'
      self.span = span_splits[1]
    elsif verb != 'notify'
      self.parent = span_splits[0]
      self.span = nil
    end
    if obj.present?
      obj_splits = obj.split('?')
      self.obj = obj_splits[0]
      self.params = obj_splits[1]
      parent_span = Rack::Utils.parse_query(obj_splits[1])['span']
      self.parent = parent_span if parent_span.present?
    end
    # if ipaddr.present?
    #   ip_ary = IPIP.instance.find(ipaddr).split("\t")
    #   province = ip_ary[1]
    #   city = ip_ary[-1]
    #   self.province = province
    #   self.city = city
    # end
    self.sid ||= REDIS.get("PING_SID:#{u}")
    return if user_agent.blank?
    if user_agent.downcase =~ /iphone/
      match = user_agent.match(/CPU iPhone OS (.*) like Mac OS X;?/)
      self.device = 'iPhone'
      self.device_sig = match&.[]1
    elsif user_agent.downcase =~ /android/
      match = user_agent.match(/Android .*; (.*) Build/)
      self.device = 'Android'
      self.device_sig = match&.[]1
    end
    self.wechat_v = user_agent.match(%r{MicroMessenger/(\d+(\.\d)?(\.\d+)?)})&.[]1
    self.lang = user_agent.match(%r{Language/(\w+) ?.*})&.[]1
  end

  def self.server_span(t)
    span = "SRV_#{SecureRandom.base58(16)}"
    Thread.new { PingLog.create(t: t, verb: 'notify', span: span, product: 'FMP') }
    span
  end
end
