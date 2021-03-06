require "heroku-api"

module GithubHerokuDeployer
  class Heroku

    def initialize(options)
      @heroku_api_key = options[:heroku_api_key]
      @heroku_app_name = options[:heroku_app_name]
    end

    def heroku
      @heroku ||= ::Heroku::API.new(api_key: @heroku_api_key)
    end

    def app
      @app ||= find_or_create_app
    end

    def find_or_create_app
      find_app
    rescue ::Heroku::API::Errors::NotFound
      create_app
    end

    def find_app
      heroku.get_app(@heroku_app_name)
    end

    def create_app
      heroku.post_app(name: @heroku_app_name)
    end

    def restart_app
      heroku.post_ps_restart(@heroku_app_name)
    end

    def destroy_app
      heroku.delete_app(@heroku_app_name)
    end

    def run(command)
      heroku.post_ps(@heroku_app_name, command)
    end

    def config_set(config_vars)
      heroku.put_config_vars(@heroku_app_name, config_vars)
    end

    def addon_add(addon, options={})
      heroku.post_addon(@heroku_app_name, addon, options)
    end

    def addon_remove(addon)
      heroku.delete_addon(@heroku_app_name, addon)
    end

    def post_ps_scale(process, quantity)
      heroku.post_ps_scale(@heroku_app_name, process, quantity)
    end

    # def add_deployhooks_http(url)
    #   add_addon("deployhooks:http", url: url)
    # end
  end
end
