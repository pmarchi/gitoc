# frozen_string_literal: true

require_relative "gitoc/version"

module Gitoc
  class Error < StandardError; end
  # Your code goes here...

  autoload :Cli, "gitoc/cli"
  autoload :Repository, "gitoc/repository"
end
