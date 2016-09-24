require 'net/http'
require 'json'

class AccountCreator
  class Error < StandardError; end

  def self.config=(config)
    @@config = config
  end

  def self.create_account!(uid, gid)
    begin
      uri = URI("#{@@config['url']}/create_account")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = { uid: uid, gid: gid }.to_json
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      fail Error.new("#{res.code} - #{res.body || "unknown"}") unless res.kind_of? Net::HTTPSuccess
    rescue SystemCallError => e
      fail Error.new(e.message)
    end
    true
  end
end
