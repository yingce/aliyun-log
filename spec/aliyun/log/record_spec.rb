RSpec.describe Aliyun::Log::Record do

	Aliyun::Log.configure do |c|
	  c.access_key_id = 'key_id'
	  c.access_key_secret ='key_secret'
	  c.project = 'test-project'
	end
	# defind model class
	class User
	  include Aliyun::Log::Record

	  logstore name: 'users', field_index: true

	  scope :children, -> { search('age <= 18') }

	  scope :country , ->(name) { search("location: #{name}") }

	  field :age, type: :long, index: false
	  field :time, type: :text, cast_type: :datetime, default: -> { Time.now }
	  field :name, default: 'Dace'
	  field :location, type: :text

	  validates :name, presence: true

	  before_save do
	    self.location = name * 2
	  end
	end

	context "test record base feature" do
		before(:each) do
			stub_request(:get, logstore_path(User.logstore_name))
        .with(query: { logstore_name: User.logstore_name })
        .to_return(body: mock_logstore(User.logstore_name).to_json)
      stub_request(:get, logstore_path(User.logstore_name, 'index'))
        .with(query: { logstore_name: User.logstore_name })
        .to_return(body: {"index_mode":"v2","line":{"token":[","," ","'","\"",";","=","(",")","[","]","{","}","?","@","&","<",">","/",":","\n","\t","\r"]},"storage":"pg","ttl":365,"lastModifyTime":1594200337}.to_json)
			stub_request(:put, logstore_path(User.logstore_name, 'index')).to_return(status: 200)
		end

		it "should be create logstore and sync index" do
			expect(User.project_name).to eq('test-project')
			expect(User.logstore_name).to eq('users')
			stub_request(:get, logstore_path(User.logstore_name))
        .with(query: { logstore_name: User.logstore_name })
        .to_return(body: mock_logstore(User.logstore_name).to_json)
      stub_request(:get, logstore_path(User.logstore_name, 'index'))
        .with(query: { logstore_name: User.logstore_name })
        .to_return(status: 400, body: {"errorCode":"IndexConfigNotExist","errorMessage":"index config doesn't exist"}.to_json)
      expect(User.has_index?).to eq(false)
      stub_request(:get, logstore_path(User.logstore_name, 'index'))
        .with(query: { logstore_name: User.logstore_name })
        .to_return(body: {"index_mode":"v2","line":{"token":[","," ","'","\"",";","=","(",")","[","]","{","}","?","@","&","<",">","/",":","\n","\t","\r"]},"storage":"pg","ttl":365,"lastModifyTime":1594200337}.to_json)
			stub_request(:put, logstore_path(User.logstore_name, 'index')).to_return(status: 200)
      User.auto_load_schema
		end

		it "should be success create logs" do
			stub_request(:post, logstore_path(User.logstore_name)).to_return(status: 200)
      user = User.new(name: 'hanmeimei', location: 'earth')
      user.save
      expect(user.location).to eq('hanmeimeihanmeimei')
		end

		it "should be succcess record query function" do
			stub_request(:get, logstore_path(User.logstore_name))
				.with(query: hash_including)
				.to_return(status: 200, body: [{"count":"1"}].to_json)
			expect(User.count).to eq(1)
		end
	end
end
