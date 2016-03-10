module AnsibleTowerClient
  class Connection
    attr_reader :connection

    def initialize(options = nil)
      raise "Credentials are required" unless options[:username] && options[:password]
      raise ":base_url is required" unless options[:base_url]
      verify_ssl = options[:verify_ssl] || OpenSSL::SSL::VERIFY_PEER
      verify_ssl = verify_ssl == OpenSSL::SSL::VERIFY_NONE ? false : true

      require 'faraday'
      require 'faraday_middleware'
      @connection = Faraday.new(options[:base_url], :ssl => {:verify => verify_ssl}) do |f|
        f.use FaradayMiddleware::FollowRedirects, :limit => 3, :standards_compliant => true
        f.request(:url_encoded)
        f.adapter(Faraday.default_adapter)
        f.basic_auth(options[:username], options[:password])
      end
    end

    def api
      @api ||= Api.new(connection)
    end

    def config
      JSON.parse(api.get("config").body)
    end

    def version
      config["version"]
    end

    def verify_credentials
      JSON.parse(api.get("me").body).fetch_path("results", 0, "username")
    end
  end
end
