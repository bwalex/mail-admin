require 'net/http'
require 'json'

class AccountCreator
  class Error < StandardError; end

  def self.create_account!(uid, gid)
    @@config ||= YAML::load(File.open('config/helper_config.yml'))

    uri = URI("#{@@config['url']}/create_account")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = { uid: uid, gid: gid }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    fail Error.new("#{res.code} - #{res.body || "unknown"}") unless res.kind_of? Net::HTTPSuccess
    true
  end
end
