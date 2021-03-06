# This software is in the public domain, furnished "as is", without technical
# support, and with no warranty, express or implied, as to its usefulness for
# any purpose.

# Require this file to build a testing environment.

ABS__FILE__ = File.expand_path(__FILE__)
$:.push(File.expand_path(__FILE__+'/../..'))

require 'extend/fileutils'
require 'extend/pathname'
require 'extend/string'
require 'exceptions'
require 'utils'

# Constants normally defined in global.rb
HOMEBREW_PREFIX        = Pathname.new('/private/tmp/testbrew/prefix')
HOMEBREW_REPOSITORY    = HOMEBREW_PREFIX
HOMEBREW_LIBRARY       = HOMEBREW_REPOSITORY+'Library'
HOMEBREW_CACHE         = HOMEBREW_PREFIX.parent+'cache'
HOMEBREW_CACHE_FORMULA = HOMEBREW_PREFIX.parent+'formula_cache'
HOMEBREW_CELLAR        = HOMEBREW_PREFIX.parent+'cellar'
HOMEBREW_LOGS          = HOMEBREW_PREFIX.parent+'logs'
HOMEBREW_USER_AGENT    = 'Homebrew'
HOMEBREW_WWW           = 'http://example.com'
HOMEBREW_CURL_ARGS     = '-fsLA'
HOMEBREW_VERSION       = '0.9-test'

MACOS = true
MACOS_VERSION = ENV.fetch('MACOS_VERSION', 10.6)
MACOS_FULL_VERSION = '10.6.8'

ORIGINAL_PATHS = ENV['PATH'].split(':').map{ |p| Pathname.new(p).expand_path rescue nil }.compact.freeze

module Homebrew extend self
  include FileUtils
end

# Test environment setup
%w{Library/Formula Library/ENV}.each do |d|
  HOMEBREW_REPOSITORY.join(d).mkpath
end

at_exit { HOMEBREW_PREFIX.parent.rmtree }

# Test fixtures and files can be found relative to this path
TEST_FOLDER = Pathname.new(ABS__FILE__).parent.realpath

def shutup
  if ARGV.verbose?
    yield
  else
    begin
      tmperr = $stderr.clone
      tmpout = $stdout.clone
      $stderr.reopen '/dev/null', 'w'
      $stdout.reopen '/dev/null', 'w'
      yield
    ensure
      $stderr.reopen tmperr
      $stdout.reopen tmpout
    end
  end
end

unless ARGV.include? "--no-compat" or ENV['HOMEBREW_NO_COMPAT']
  $:.unshift(File.expand_path("#{ABS__FILE__}/../../compat"))
  require 'compatibility'
end

require 'test/unit' # must be after at_exit
require 'extend/ARGV' # needs to be after test/unit to avoid conflict with OptionsParser
require 'extend/ENV'
ARGV.extend(HomebrewArgvExtension)
ENV.extend(HomebrewEnvExtension)

begin
  require 'rubygems'
  require 'mocha/setup'
rescue LoadError
  warn 'The mocha gem is required to run some tests, expect failures'
end

module VersionAssertions
  def version v
    Version.new(v)
  end

  def assert_version_equal expected, actual
    assert_equal Version.new(expected), actual
  end

  def assert_version_detected expected, url
    assert_equal expected, Version.parse(url).to_s
  end

  def assert_version_nil url
    assert_nil Version.parse(url)
  end
end

module Test::Unit::Assertions
  def assert_empty(obj, msg=nil)
    assert_respond_to(obj, :empty?, msg)
    assert(obj.empty?, msg)
  end if RUBY_VERSION.to_f <= 1.8
end
