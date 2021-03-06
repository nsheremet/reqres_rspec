require 'reqres_rspec/version'
require 'reqres_rspec/utils'
require 'reqres_rspec/configuration'
require 'reqres_rspec/collector'
require 'reqres_rspec/formatters'
require 'reqres_rspec/formatters/base'
require 'reqres_rspec/formatters/html'
require 'reqres_rspec/formatters/json'
require 'reqres_rspec/formatters/pdf'
require 'reqres_rspec/uploaders'
require 'reqres_rspec/uploaders/amazon_s3'
require 'pry'

if defined?(RSpec) && ENV['REQRES_RSPEC'] == '1'
  collector = ReqresRspec::Collector.new

  RSpec.configure do |config|
    config.after(:each) do |example|
      if defined?(Hanami)
        self_request = self.action rescue false
        self_response = response rescue false
      end

      if defined?(self_request) && self_request && defined?(self_response) && self_response
        begin
          collector.collect(self, example, self_request, self_response)
        rescue Rack::Test::Error
          #
        rescue NameError
          raise $!
        end
      end
    end

    config.after(:suite) do
      if collector.records.size > 0
        collector.sort
        ReqresRspec::Formatters.process(collector.records)
        ReqresRspec::Uploaders.upload if ENV['REQRES_UPLOAD']
      end
    end
  end

  def process_example?(meta_data, example)
    meta_data[:type] == :request && !(meta_data[:skip_reqres] || example.metadata[:skip_reqres])
  end
end
