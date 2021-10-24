require "pathname"
require "yaml"
require "thor"

class Gitoc::Cli < Thor
  include Thor::Actions

  class_option :base, default: "~/git", desc: "Local git base directory"

  desc "list", "List TOC"
  def list
    list = YAML.load_file(backup).map do |attribute|
      [attribute[:path], attribute[:url].to_s]
    end

    print_table list
  end

  desc "dump", "Dump git repository metadata into a TOC"
  def dump
    init_base

    repositories = Gitoc::Repository.base.glob("**/.git").map do |git_dir|
      Gitoc::Repository.new(git_dir.parent)
    end.sort_by(&:path)

    # Write git_toc file
    backup.write repositories.map(&:to_hash).to_yaml
  end

  desc "clone", "Fetch TOC and clone all repository"
  def clone
    init_base

    repositories = YAML.load_file(backup).map do |attributes|
      Gitoc::Repository.load attributes
    end

    repositories.each_with_index do |repo, index|
      puts
      say "~/#{repo.path.relative_path_from(home)} (#{index+1}/#{repositories.count})", :cyan

      if repo.url.nil? || repo.url.empty?
        say "Skip repository with no remote.origin.url", :red
        next
      end

      repo.clone
    end
  end

  private

  def init_base
    Gitoc::Repository.base = Pathname.new(options[:base]).expand_path
  end

  def backup
    @backup ||= Pathname.new("~/Dropbox/settings/git_toc.yaml").expand_path
  end

  def home
    @home ||= Pathname.new(ENV["HOME"])
  end
end