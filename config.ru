require "rubygems"
require "geminabox"

require "faraday"
require "faraday-http-cache"
require "faraday_middleware"
require "active_support"

CACHE_STORE = ActiveSupport::Cache::FileStore.new(File.expand_path('../var/cache', __FILE__))

module Geminabox

  class FaradayAdapter < HttpAdapter

    def get(*args)
      adapter.get do |req|
        req.url *args
        req.timeout 600
        req.open_timeout 600
      end
    end

    def get_content(*args)
      response = adapter.get(*args)
      response.body
    end

    def post(*args)
      adapter.post(*args)
    end

    # Note that this configuration turns SSL certificate verification off.
    # To set up the adapter for your environment see:
    # https://github.com/lostisland/faraday/wiki/Setting-up-SSL-certificates
    # def set_auth(uri, username = nil, password = nil)
    #   connection = Faraday.new url: uri, ssl: {verify: false} do |faraday|
    #     faraday.adapter http_engine
    #     faraday.proxy(ENV['http_proxy']) if ENV['http_proxy']
    #   end
    #   connection.basic_auth username, password if username
    #   connection
    # end

    def adapter
      @adapter ||= Faraday.new do |faraday|
        faraday.use FaradayMiddleware::FollowRedirects, limit: 5 
        faraday.use Faraday::HttpCache, logger: ActiveSupport::Logger.new(STDOUT), serializer: Marshal, store: CACHE_STORE
        faraday.adapter Faraday.default_adapter
      end
    end

    # def http_engine
    #   :net_http  # make requests with Net::HTTP
    # end

    # def options
    #   lambda {|faraday|
    #     faraday.adapter http_engine
    #     faraday.proxy(ENV['http_proxy']) if ENV['http_proxy']
    #   }
    # end

  end
end

use Rack::CommonLogger, STDOUT
Geminabox.data           = "var/geminabox-data" # ... or wherever
Geminabox.build_legacy   = false
Geminabox.rubygems_proxy = true
Geminabox.http_adapter   = Geminabox::FaradayAdapter.new
run Geminabox::Server
