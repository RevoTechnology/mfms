require 'bundler/setup'
Bundler.setup
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require 'mfms'

RSpec.configure do |config|
end
