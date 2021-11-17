require "pathname"
require "yaml"
require "thor"

class Gitoc::Cli < Thor
  include Thor::Actions

  class_option :base, default: "~/git", desc: "Local git base directory"
  class_option :toc, default: "~/.gitoc.yaml", desc: "GiTOC file"

  desc "check", "Check local repositories and GiTOC file"
  def check
    init_base

    # Get all repositories from the filesystem
    # and tag them with :fs
    repositories = repositories_fs.map do |repository_fs|
      [repository_fs, [:fs]]
    end

    # Add missing repositories from the GiTOC file
    # and tag all repositories from the GiTOC file with :toc
    repositories_gitoc.each do |repository_gitoc|
      _, tags = repositories.find {|repository_fs, _| repository_fs == repository_gitoc }
      if tags
        tags << :toc
      else
        repositories << [repository_gitoc, [:toc]]
      end
    end

    # Sort repositories list
    # and build table rows: [path, url, comment]
    rows = repositories.sort_by {|repository, _| repository.rel_path }.map do |repository, tags|
      path, url = repository.to_hash.values
      url = "-" if url.nil? || url.empty?
      comment = tags.include?(:fs) && tags.include?(:toc) ? "" : {fs: "not in GiTOC", toc: "not on filesystem"}[tags.first]

      [path, url, comment]
    end

    print_table rows  
  end

  desc "generate", "Recursively scan base for git repositories and generate/update GiTOC file"
  def generate
    init_base

    toc = repositories_fs.map(&:to_hash)

    # Write git_toc file
    gitoc.write toc.to_yaml
    puts "Write #{gitoc}"
  end

  desc "clone", "Read GiTOC file and clone all repositories"
  def clone
    init_base

    each_repository do |repo|
      if repo.exist?
        puts "Skip repository, #{repo.path} already exists."
        next
      end

      repo.clone
    end
  end

  desc "pull", "Read GiTOC file and pull all repositories"
  def pull
    init_base

    each_repository do |repo|
      unless repo.exist?
        puts "Skip repository, #{repo.path} doesn't exist."
        next
      end

      repo.pull
    end
  end

  desc "clone-or-pull", "Read GiTOC file and clone/pull all repositories"
  def clone_or_pull
    init_base

    each_repository do |repo|
      if repo.exist?
        repo.pull
      else
        repo.clone
      end
    end
  end

  private

  def init_base
    Gitoc::Repository.base = Pathname.new(options[:base]).expand_path
  end

  def gitoc
    @gitoc ||= Pathname.new(options[:toc]).expand_path
  end

  def repositories_gitoc
    @repositories_gitoc ||= begin
      unless gitoc.exist?
        say "#{gitoc} not found", :red
        exit 1
      end

      YAML.load_file(gitoc).map do |attributes|
        Gitoc::Repository.load attributes
      end
    end
  end

  def repositories_fs
    @repositories_fs ||= Gitoc::Repository.base.glob("**/.git").map do |git_dir|
      Gitoc::Repository.new(git_dir.parent)
    end.sort_by(&:path)
  end

  def each_repository
    repositories_gitoc.each_with_index do |repo, index|
      puts
      say "~/#{repo.path.relative_path_from(home)} (#{index + 1}/#{repositories_gitoc.count})", :cyan

      unless repo.url?
        say "Skip repository with no remote.origin.url", :red
        next
      end

      yield repo
    end
  end
      
  def home
    @home ||= Pathname.new(ENV["HOME"])
  end
end
