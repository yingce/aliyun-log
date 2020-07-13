RSpec.describe Aliyun::Log::Project do

	context "get list projects" do
		it "should list projects" do
			data = { count: 5, total: 5, projects: 5.times.map { |t| mock_project(t.to_s) } }
			stub_request(:get, request_path).to_return(body: data.to_json)
			projects = client.list_projects
			expect(projects['count']).to eq(5)
		end

		it "should unauthorized projects" do
			mock_data = {"errorCode":"Unauthorized","errorMessage":"denied by sts or ram, action: log:ListProject, resource: acs:log:cn-beijing:iamironman:project/*"}
			stub_request(:get, request_path).to_return(status: 401, body: mock_data.to_json)
			begin
	  		projects = client.list_projects
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('Unauthorized')
	  		expect(e.http_code).to eq(401)
	  	end
		end
	end

	context "test get single project" do
	  it "should get project" do
	  	stub_request(:get, request_path(project: project_name))
	  		.with(query: { projectName: project_name })
	  		.to_return(body: mock_project(project_name).to_json)
	    project = client.get_project(project_name)
	    expect(project.name).to eq(project_name)
	  end

	  it "should unauthorized project" do
			mock_data = {"errorCode":"Unauthorized","errorMessage":"the parent of sub user must be project owner"}
			stub_request(:get, request_path(project: project_name))
				.with(query: { projectName: project_name })
				.to_return(status: 401, body: mock_data.to_json)
			begin
	  		client.get_project(project_name)
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('Unauthorized')
	  		expect(e.http_code).to eq(401)
	  	end
		end

	  it "should get not exist project with exception" do
	  	mock_data = {"errorCode":"ProjectNotExist","errorMessage":"The Project does not exist : #{project_name}"}
	  	stub_request(:get, request_path(project: project_name))
	  		.with(query: { projectName: project_name })
	  		.to_return(status: 404, body: mock_data.to_json)
	  	begin
	  		project = client.get_project(project_name)
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('ProjectNotExist')
	  		expect(e.http_code).to eq(404)
	  	end
	  end
	end

	context "test create project" do
		it "should success create project" do
			stub_request(:post, request_path(project: project_name)).to_return(status: 200)
			resp = client.create_project(project_name, 'description')
			expect(resp.code).to eq(200)
		end

		it "should unauthorized create project" do
			mock_data = {"errorCode":"Unauthorized","errorMessage":"denied by sts or ram, action: log:CreateProject, resource: acs:log:cn-beijing:iamironman:project/zhongguan1"}
			stub_request(:post, request_path(project: project_name)).to_return(status: 401, body: mock_data.to_json)
			begin
	  		client.create_project(project_name, 'description')
	  	rescue Aliyun::Log::ServerError => e
	  		expect(e.error_code).to eq('Unauthorized')
	  		expect(e.http_code).to eq(401)
	  	end
		end
	end

	context "test delete project" do
		it "should success delete project" do
			stub_request(:delete, request_path(project: project_name)).to_return(status: 200)
			resp = client.delete_project(project_name)
			expect(resp.code).to eq(200)
		end
	end
end
