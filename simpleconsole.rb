#!/usr/local/bin/ruby
require 'rubygems'
require 'simpleconsole'

class Controller < SimpleConsole::Controller
  params :string => {:n => :name, :w => :word}

  def usage
  end

  def print
    @name = params[:name]
    @word = params[:word]
  end
end

class View < SimpleConsole::View
  def print
    puts "Your name is " + @name + "."
    puts "You wanted me to say the word " + @word + "."
  end
  def usage
    puts "Here is usage"
  end
end

SimpleConsole::Application.run(ARGV, Controller, View)