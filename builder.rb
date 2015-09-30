#!/usr/local/bin/ruby

require "rubygems"
require "irb"
require 'hirb'
extend Hirb::Console

class Constants

  SZN_RUBY_VER = "szn-ruby2.1-"
  BASE_PATH = File.expand_path(File.dirname(__FILE__))
  TEMPLATE_PATH = BASE_PATH + "/template/szn-ruby2.1-xxx"
  PACKAGES_PATH = BASE_PATH + "/packages/"
  GEM_API_URL='http://rubygems.org/api/v1/gems/'
  AUTHOR = "Luka Musin"
  EMAIL = "luka.musin@firma.seznam.cz"

end

require_relative "classes.rb"

gems = DependentGemsCollection.new(ARGV[0])


choices = []
choices = menu  gems.map { |i| Hash[:gemname =>  i.gemname, :version => i.version, :depends => i.depends]}, :fields=>[:gemname, :version, :depends], :two_d=>true, :prompt => "Delete gems don't want to build. Choose:"

gems.delete { |i| choices.include? i.gemname }

gems.map {|i| i.write; p "Writing gem #{i.gemname}..." }




