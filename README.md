[![Gem Version](https://badge.fury.io/rb/gitoc.svg)](https://badge.fury.io/rb/gitoc)

# Gitoc

GiTOC generates a table of contents from a local directory tree of git repositories. Use this GiTOC file to clone all your git repositories to a new location (computer) or run a command on all your repositories.

## Installation

    $ gem install gitoc

## Usage

The local directory tree of your git repositories defaults to `~/git` and the default GiTOC file path is set to `~/.gitoc.yaml`. Use `--base=DIRECTORY` and `--toc=GiTOC-FILE` to overwrite these defaults.

First you have to generate a GiTOC file with

    $ gitoc generate

Then you can run things on your local repositories

    # Run git pull on all your repositories
    $ gitoc pull

    # Clone all git repositories to a new location using the same directory structure specified in your GiTOC file.

    # ... to a new location on the same computer
    $ gitoc clone --base=NEW-DIRECTORY

    # ... to a new computer (copy/move your GiTOC file first)
    $ gitoc clone

    # Check your GiTOC file
    $ gitoc check

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/gitoc.
