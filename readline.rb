#!/usr/local/bin/ruby

require 'readline'

require_relative "classes.rb"

gems = DependentGemsCollection.new(ARGV[0])

Pry.config.editor = "vim"



while line = Readline.readline('> ', true)

  gems.class.instance_variables.each do |properties|

    gems.each do |gem|

      p gem.send(properties)

    end
  end

    p line
end
