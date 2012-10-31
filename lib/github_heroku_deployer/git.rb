require "git"
require "git-ssh-wrapper"

module GithubHerokuDeployer
  class Git

    def initialize(options)
      @heroku_repo = options[:heroku_repo]
      @github_repo = options[:github_repo]
      @id_rsa = options[:id_rsa]
      @logger = options[:logger]
      @repo_dir = options[:repo_dir]
    end

    def push_app_to_heroku(remote="heroku", branch="master")
      wrapper = ssh_wrapper
      `cd #{repo.dir}; git remote rm #{remote}` if repo.remote(remote).url
      repo.add_remote(remote, @heroku_repo)
      @logger.info "deploying #{repo.dir} to #{repo.remote(remote).url} from branch #{branch}"
      `echo cd #{repo.dir}; env #{wrapper.git_ssh} git push -f #{remote} #{branch} 2>log/err.log`
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
      @folder ||= File.join(@repo_dir, Zlib.crc32(@github_repo).to_s)
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
      `echo env #{wrapper.git_ssh} git clone #{@github_repo} #{folder} 2>log/err.log`
    ensure
      wrapper.unlink
    end

    def pull
      wrapper = ssh_wrapper
      dir = Dir.pwd # need to cd back to here
      @logger.info "pulling from #{folder}"
      `echo cd #{folder}; env #{wrapper.git_ssh} git pull; cd #{dir} 2>log/err.log`
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
