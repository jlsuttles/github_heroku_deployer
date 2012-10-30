require "git"
require "git-ssh-wrapper"

module GithubHerokuDeployer
  class Git

    def initialize(options)
      @heroku_repo = options[:heroku_repo]
      @github_repo = options[:github_repo]
      @id_rsa = options[:id_rsa]
      @logger = options[:logger]
    end

    def push_app_to_heroku(remote="heroku", branch="master")
      wrapper = ssh_wrapper
      repo.add_remote("heroku", @heroku_repo) unless repo.remote("heroku").url
      @logger.info "deploying #{repo.dir} to #{repo.remote("heroku").url} from branch #{branch}"
      `cd #{repo.dir}; env #{wrapper.git_ssh} git push -f #{remote} #{branch}`
    ensure
      wrapper.unlink
    end

    def repo
      @repo ||= setup_repo
    end

    def setup_repo
      clone_or_pull
      open
    end

    def folder
      @folder ||= "tmp/repos/#{Zlib.crc32(@github_repo)}"
    end

    def clone_or_pull
      !exists_locally? ? clone : pull
    end

    def exists_locally?
      File.exists?(File.join(folder, ".git", "config"))
    end

    def clone
      wrapper = ssh_wrapper
      @logger.info "cloning #{@github_repo} to #{folder}"
      `env #{wrapper.git_ssh} git clone #{@github_repo} #{folder}`
    ensure
      wrapper.unlink
    end

    def pull
      wrapper = ssh_wrapper
      dir = Dir.pwd # need to cd back to here
      @logger.info "pulling from #{dir}/#{folder}"
      `cd #{dir}/#{folder}; env #{wrapper.git_ssh} git pull; cd #{dir}`
    ensure
      wrapper.unlink
    end

    def open
      ::Git.open(folder)
    end

    def ssh_wrapper
      GitSSHWrapper.new(private_key_path: id_rsa_path)
    end

    def id_rsa_path
      file = Tempfile.new("id_rsa")
      file.write(@id_rsa)
      file.rewind
      file.path
    end
  end
end
