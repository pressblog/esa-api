module EsaApi
  # Configures global settings for esa-api
  #   EsaApi.configure do |config|
  #     something...
  #   end
  class << self
    def configure
      yield config

      client

      nil
    end

    def config
      @_config ||= Config.new
    end

    def groups
      config.groups
    end

    def client(access_token: config.access_token)
      @_client ||= Esa::Client.new(access_token: access_token)
    end

    def user
      @_user ||= User.new(client.user)
    end

    def teams
      Team.all
    end
  end

  class Config
    attr_accessor :groups, :access_token

    def initialize(access_token: nil)
      @groups = [:default, ENV.fetch('RUN_ENV', 'development')]
      @access_token = access_token || ENV.fetch('ESA_ACCESS_TOKEN')
    end
  end

  class HTTPClient
    class RequestFailed < StandardError; end
    class NotFoundMember < StandardError; end

    class BroadcastErrorClass
      class << self
        def broadcast(message)
          case message
          when /Bad Request: \w+ is not a member of this team/
            [EsaApi::HTTPClient::NotFoundMember, message]
          else
            [EsaApi::HTTPClient::RequestFailed, message]
          end
        end
      end
    end

    class Headers
      attr_reader :date, :connection, :ratelimit_limit, :ratelimit_remaining,
        :ratelimit_reset, :runtime

      def initialize(headers)
        @date                 = headers["date"] || headers["Date"]
        @connection           = headers["connection"] || headers["Connection"]
        @ratelimit_limit      = headers["x-ratelimit-limit"] || headers["X-ratelimit-limit"]
        @ratelimit_remaining  = headers["x-ratelimit-remaining"] || headers["X-ratelimit-remaining"]
        @ratelimit_reset      = headers["x-ratelimit-reset"] || headers["X-ratelimit-reset"]
        @runtime              = headers["x-runtime"] || headers["X-runtime"]
      end
    end

    class << self
      def request
        response = new(yield)
        if response.status >= 400
          error_object = BroadcastErrorClass.broadcast(response.body["message"])
          raise *error_object
        else
          response
        end
      end
    end

    attr_reader :body, :headers, :status

    def initialize(response)
      @body = response.body
      @headers = Headers.new(response.headers)
      @status = response.status
    end
  end

  class Team
    class NotFoundTeamError < StandardError; end

    @@teams = nil
    @@current_team = ''

    class << self
      def all
        return @@teams if @@teams.is_a? Array

        EsaApi.client.teams.body["teams"].each do |data|
          Team.create(data)
        end
        @@teams
      end

      def create(data)
        @@teams = [] unless @@teams.is_a? Array
        team = new(data)
        @@teams << team
        team
      end

      def find_by_name(name)
        all.find do |team|
          team.name == name
        end
      end

      def exists?(name)
        all.any? do |team|
          team.name == name
        end
      end

      def current_team=(team)
        if team.is_a? EsaApi::Team
          team = team.name
        end
        unless exists?(team)
          raise NotFoundTeamError, "Not found #{team} team"
        end
        EsaApi.client.current_team = team
      end

      def current_team
        EsaApi.client.current_team
      end
    end

    attr_reader :name

    def initialize(hash)
      @name = hash["name"]
    end
  end

  class Post
    class << self
      def search_all(q: '', per_page: 100)
        posts = []
        page = 1
        next_page = 1

        begin
          page = next_page
          response = EsaApi.client.posts({ q: q, page: page, per_page: per_page })
          response.body["posts"].each do |post|
            posts << new(post)
          end
          unless response.body["next_page"].nil?
            next_page = response.body["next_page"].to_i
          end
        end while page != next_page

        posts
      end
    end

    attr_reader :number, :name, :body_md, :tags, :category, :wip, :created_by

    def initialize(data)
      @number     = data["number"]
      @name       = data["name"]
      @body_md    = data["body_md"]
      @tags       = data["tags"]
      @category   = data["category"]
      @wip        = data["wip"]
      @created_by = data["created_by"]
    end

    def user
      EsaApi::User.new(created_by).screen_name
    end

    def push
      request_params = params
      try = 0
      begin
        try += 1
        HTTPClient.request do
          EsaApi.client.create_post(request_params)
        end
      rescue EsaApi::HTTPClient::NotFoundMember => e
        request_params.merge!({ user: esa_bot })
        retry if try <= 1
      end
    end

    def esa_bot
      "esa_bot"
    end

    def params
      {
        name: name,
        body_md: body_md,
        tags: tags,
        category: category,
        wip: wip,
        user: user
      }
    end
  end

  class User
    attr_reader :id, :name, :screen_name, :email, :icon

    def initialize(hash)
      @id           = hash["id"]
      @name         = hash["name"]
      @screen_name  = hash["screen_name"]
      @email        = hash["email"]
      @icon         = hash["icon"]
    end
  end
end
