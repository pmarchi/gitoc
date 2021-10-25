require "pathname"
require "yaml"
require "thor"

class Gitoc::Cli < Thor
  include Thor::Actions

  class_option :base, default: "~/git", desc: "Local git base directory"

  desc "check TOC-FILE", "Check TOC-FILE"
  def check toc
    init_base
    repositories = load_toc! toc

    list = repositories.map do |repo|
      path, url = repo.to_hash.values
      path = set_color(path, :red) if url.nil? || url.empty?
      [path, url]
    end

    print_table list
  end

  desc "dump TOC-FILE", "Dump git repository metadata into a TOC"
  def dump toc
    init_base

    repositories = Gitoc::Repository.base.glob("**/.git").map do |git_dir|
      Gitoc::Repository.new(git_dir.parent)
    end.sort_by(&:path)

    # Write git_toc file
    File.write toc, repositories.map(&:to_hash).to_yaml
  end

  desc "clone TOC-FILE", "Read TOC and clone all repositories"
  def clone toc
    init_base
    repositories = load_toc! toc

    repositories.each_with_index do |repo, index|
      print_repository_label repo, index, repositories.count

      if repo.exist?
        say "Skip repository, #{repo.path} already exists.", :red
        next
      end

      unless repo.url?
        say "Skip repository with no remote.origin.url", :red
        next
      end

      repo.clone
    end
  end

  desc "pull TOC-FILE", "Read TOC and pull all repositories"
  def pull toc
    init_base
    repositories = load_toc! toc

    repositories.each_with_index do |repo, index|
      print_repository_label repo, index, repositories.count

      unless repo.exist?
        say "Skip repository, #{repo.path} doesn't exist.", :red
        next
      end

      unless repo.url?
        say "Skip repository with no remote.origin.url", :red
        next
      end

      repo.pull
    end
  end

  private

  def init_base
    Gitoc::Repository.base = Pathname.new(options[:base]).expand_path
  end

  def load_toc! toc
    unless File.exist? toc
      say "#{toc} not found", :red
      exit 1
    end

    YAML.load_file(toc).map do |attributes|
      Gitoc::Repository.load attributes
    end
  end

  def print_repository_label repo, count, total
    puts
    say "~/#{repo.path.relative_path_from(home)} (#{count + 1}/#{total})", :cyan
  end

  def home
    @home ||= Pathname.new(ENV["HOME"])
  end
end
