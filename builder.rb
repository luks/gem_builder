#!/usr/local/bin/ruby

require "rubygems"
require "irb"
require 'hirb'
extend Hirb::Console

class Constants

  BASE_PATH = File.expand_path(File.dirname(__FILE__))
  SZN_RUBY_VER = "szn-ruby-2.1-"
  GEM_API_URL='http://rubygems.org/api/v1/gems/'

end


require_relative "classes.rb"

gems = DependentGemsCollection.new(ARGV[0])

Pry.config.editor = "vim"


#table gems.dependency

#table gems.map {|i| [i.gemname, i.version]}

#Hash[[:gemname,:version, :depends], gems.map { |i| [i.gemname, i.version, i.depends]},


choices = menu  gems.map { |i| Hash[:gemname =>  i.gemname, :version => i.version, :depends => i.depends]}, :fields=>[:gemname, :version, :depends], :two_d=>true, :prompt => "Delete gems don't want to build. Choose:"

gems.delete { |i| choices.include? i.gemname } 



edit = menu  gems.map { |i| Hash[:gemname =>  i.gemname, :version => i.version, :depends => i.depends]}, :fields=>[:gemname, :version, :depends], :two_d=>true, :prompt => "Edit gems:"

for_edit = gems.update { |i|  edit.include? i.gemname }
a = for_edit.each
binding.pry
  
gems.map {|i| i.write; p "Writing #{i.gemname}.." }

#menu [{:a=>1, :b=>2}, {:a=>3, :b=>4}], :fields=>[:a,:b], :two_d=>true



