require './init'

require 'securerandom'
require 'sass/plugin/rack'

require './web'

use ActiveRecord::ConnectionAdapters::ConnectionManagement
use Sass::Plugin::Rack

use Rack::Session::Cookie,
  :expire_after => 14400,
  :secret       => SecureRandom.hex(64)

run Rack::Cascade.new [Web]
