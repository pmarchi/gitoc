require "open3"
require "pathname"

class Gitoc::Repository

  class << self
    attr_accessor :base

    def load attribute
      new base.join(attribute[:path]), attribute[:url]
    end
  end
  
  # Path to the git repository
  attr_reader :path

  def initialize path, url=nil
    @path = Pathname.new(path).expand_path
    @url = url
  end

  def to_hash
    {
      path: path.relative_path_from(self.class.base).to_s,
      url: url,
    }
  end

  def url?
    ! (url.nil? || url.empty?)
  end

  def url
    @url ||= begin
      out, _status = run_in path, "git config remote.origin.url"
      out.chomp
    end
  end

  def clone
    return unless url
    path.parent.mkpath
    run_in path.parent, "git clone #{url}"
  end

  def run_in path, cmd
    Dir.chdir path do
      Open3.capture2 cmd
    end
  end
end