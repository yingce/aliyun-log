RSpec.describe Aliyun::Log::Logstore do

	context "get list logstores" do
		it "should list logstores" do
			mock_data = { count: 2, total: 2, logstores: ["nginx_logs", "apache_logs"] }
			stub_request(:get, logstore_path).to_return(body: mock_data.to_json)
			logstores = project.list_logstores
			expect(logstores['count']).to eq(2)
		end

		it "should unauthorized logstores" do
			mock_data = {"errorCode": "Unauthorized", "errorMessage": "the parent of sub user must be project owner"}
			stub_request(:get, logstore_path).to_return(status: 401, body: mock_data.to_json)
			begin
	  		logstores = project.list_logstores
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('Unauthorized')
	  		expect(e.http_code).to eq(401)
	  	end
		end
	end

	context "test get single logstore" do
	  it "should success get logstore" do
	    logstore = get_logstore
	    expect(logstore.name).to eq(logstore_name)
	  end

	  it "should raise exception when get not exist logstore" do
	  	mock_data = {"errorCode": "LogStoreNotExist", "errorMessage": "logstore test-logstore does not exist"}
	  	stub_request(:get, logstore_path(logstore_name))
	  		.with(query: { logstore_name: logstore_name })
	  		.to_return(status: 404, body: mock_data.to_json)
	  	begin
	  		logstore = project.get_logstore(logstore_name)
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('LogStoreNotExist')
	  		expect(e.http_code).to eq(404)
	  	end
	  end
	end

	context "test create and delete logstore" do
		it "should success create logstore" do
			stub_request(:post, logstore_path('')).to_return(status: 200)
			resp = project.create_logstore(logstore_name)
			expect(resp.code).to eq(200)
		end

		it "should success delete logstore" do
			stub_request(:delete, logstore_path(logstore_name)).to_return(status: 200)
			resp = project.delete_logstore(logstore_name)
			expect(resp.code).to eq(200)
		end
	end

	context "test create update and delete index" do
		it "should success create index" do
	    stub_request(:post, logstore_path(logstore_name, 'index')).to_return(status: 200)
	    resp = get_logstore.create_index_line
	    expect(resp.code).to eq(200)
	  end

	  it "should raise exception when index alread exists" do
	  	stub_request(:get, logstore_path(logstore_name))
	  		.with(query: { logstore_name: logstore_name })
	  		.to_return(body: mock_logstore(logstore_name).to_json)
	    logstore = project.get_logstore(logstore_name)
	    mock_data = {"errorCode": "IndexAlreadyExist", "errorMessage": "log store index is already created"}
	    stub_request(:post, logstore_path(logstore_name, 'index'))
	    	.to_return(status: 400, body: mock_data.to_json)
			begin
		    logstore.create_index_line
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('IndexAlreadyExist')
	  		expect(e.http_code).to eq(400)
	  	end
	  end

	  it "should success update index" do
	    stub_request(:put, logstore_path(logstore_name, 'index')).to_return(status: 200)
	    resp = get_logstore.update_index({ key1: { type: :text } })
	    expect(resp.code).to eq(200)
	  end

	  it "should success delete index" do
	    stub_request(:delete, logstore_path(logstore_name, 'index')).to_return(status: 200)
	    resp = get_logstore.delete_index
	    expect(resp.code).to eq(200)
	  end

	  it "should exception delete index" do
	    stub_request(:delete, logstore_path(logstore_name, 'index'))
	    	.to_return(status: 500, body: { "errorCode": "InternalServerError", "errorMessage": "log store index not created"}.to_json)
	    begin
		    get_logstore.delete_index
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('InternalServerError')
	  		expect(e.http_code).to eq(500)
	  	end
	  end
	end

	context "test put logs" do
		it "should put logs and get logs success" do
			stub_request(:post, logstore_path(logstore_name)).to_return(status: 200)
			resp = get_logstore.put_log({ key1: "value1", key2: "value2" })
			expect(resp.code).to eq(200)
			to = Time.now.to_i
			stub_request(:get, logstore_path(logstore_name))
				.with(query: { from: 0, to: to, type: 'log' })
				.to_return(status: 200, body: [{"key1": "value1", "key2": "value2"}].to_json)
			resp = get_logstore.get_logs(from: 0, to: to)
			expect(resp.body).to eq([{"key1": "value1", "key2": "value2"}].to_json)
		end
	end
end
