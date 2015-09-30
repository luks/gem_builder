#!/usr/local/bin/ruby


require 'net/http'
require 'json'
require 'pp'
require 'pry'
require 'open-uri'
require "fiber"


class Hashes2Objects

  def initialize(object)
    @object = hashes2ostruct(object)
  end

  def method_missing(name, *args, &block)
    begin
      @object.send(name)
    rescue NoMethodError => e
      return nil
    end
  end

  private

  def hashes2ostruct(object)
    return case object
    when Hash
      object = object.clone
      object.each do |key, value|
        object[key] = hashes2ostruct(value)
      end
      OpenStruct.new(object)
    when Array
      object = object.clone
      object.map! { |i| hashes2ostruct(i) }
    else
      object
    end
  end
end

class GemApiObject < Hashes2Objects

end


class GemDebian

  SZN_RUBY_VER = "szn-ruby2.1-"
  BASE_PATH = File.expand_path(File.dirname(__FILE__))
  TEMPLATE_PATH = GemDebian::BASE_PATH + "/template/szn-ruby2.1-xxx"
  PACKAGES_PATH = GemDebian::BASE_PATH + "/packages/"

  attr_accessor :build_depends, :architecture
  attr_reader :gemname, :version, :description, :homepage, :gem_uri, :package, :depends, :source, :gem_exact_name, :template_path, :package_path

  def initialize(gem)
    @gemname        = gem.name
    @version        = gem.version
    @description    = gem.info
    @homepage       = gem.homepage_uri
    @gem_uri        = gem.gem_uri
    @package        = GemDebian::SZN_RUBY_VER + gem.name
    @depends        = gem.dependencies.runtime.count > 0 ? ", " + gem.dependencies.runtime.map {|i|  GemDebian::SZN_RUBY_VER + i.name }.join(", ") : ""
    @build_depends  = ""
    @architecture   = "all"
    @source         = GemDebian::SZN_RUBY_VER + gem.name
    @gem_exact_name = gem.gem_uri.split("/").last
    @template_path  = GemDebian::TEMPLATE_PATH
    @packages_path  = GemDebian::PACKAGES_PATH + GemDebian::SZN_RUBY_VER + gem.name

  end

  def write
    copy_template
    modify_debian_files
  end

  private
  def copy_template
    if !File.directory?(@packages_path)
      FileUtils.cp_r(@template_path, @packages_path)
      File.open(@packages_path+'/'+@gem_exact_name , "wb") do |file|
        file.write open(@gem_uri).read
      end
    end
  end

  def modify_debian_files

    control     =  File.read(@packages_path+'/debian/control')
    rules       =  File.read(@packages_path+'/debian/rules')
    changelog   =  File.read(@packages_path+'/debian/changelog')

    control = control.gsub(/xxx-source/,  @source)
    control = control.gsub(/xxx-builds-depends/,  @build_depends)
    control = control.gsub(/xxx-homepage/,  @homepage)
    control = control.gsub(/xxx-package/,  @package)
    control = control.gsub(/xxx-architecture/,  @architecture)
    control = control.gsub(/xxx-depends/,  @depends)
    control = control.gsub(/xxx-architecture/,  @architecture)
    control = control.gsub(/xxx-description/,  @description)

    rules = rules.gsub(/xxx-gemname/, @gemname)
    rules = rules.gsub(/xxx-version/, @version)

    changelog = changelog.gsub(/szn-ruby2.1-xxx/, "#{@package}")
    changelog = changelog.gsub(/(xxx-1)/, "#{@version}-1")

    File.open(@packages_path+'/debian/control', "w") {|file| file.puts control}
    File.open(@packages_path+'/debian/rules', "w") {|file| file.puts rules}
    File.open(@packages_path+'/debian/changelog', "w") {|file| file.puts changelog}

  end
end

module GemsEnumerable

  def map
    out = []
    each { |e| out << yield(e) }
    out
  end

  def select
    out = []
    each { |e| out << e if yield(e) }
    out
  end

  def delete
    out = []
    each { |e| out << e unless yield(e) }
    out
  end

  def sort_by
    map { |a| [yield(a), a] }.sort.map { |a| a[1] }
  end

end

class GemsEnumerator

  include GemsEnumerable

  def initialize(target, iter)
    @target = target
    @iter   = iter
  end

  def each(&block)
    @target.send(@iter, &block)
  end

  def next
    @fiber ||= Fiber.new do
      each { |e| Fiber.yield(e) }
      raise StopIteration
    end
    if @fiber.alive?
      @fiber.resume
    else
      raise StopIteration
    end
  end

end

class DependentGemsCollection

  include GemsEnumerable

  GEM_API_URL='http://rubygems.org/api/v1/gems/'

  attr_accessor :dependency, :gems

  def initialize(gem)
    @dependency = {}
    @gems = []
    gem_dependency_recursive(gem)
  end

  def <<(object)
    @gems << object
  end

  def delete &block
    @gems = super &block
  end

  def update &block
    @gems.select &block
  end

  def each
    if block_given?
      @gems.each { |e| yield(e) }
    else
      GemsEnumerator.new(self, :each)
    end
  end


  private

  def gem_dependency_recursive(gem)

    gem_api_url = DependentGemsCollection::GEM_API_URL + gem + '.json'
    resp = Net::HTTP.get_response(URI.parse(gem_api_url))
    buffer = resp.body
    result = JSON.parse(buffer)
    object = GemApiObject.new(JSON.parse(buffer))
    @dependency[gem] = [] unless @dependency.has_key? gem
    object.dependencies.runtime.each do |struct|
      next if @dependency[gem].include? struct.name + ' ' + struct.requirements
      gem_dependency_recursive(struct.name)
      @dependency[gem] << struct.name + ' ' + struct.requirements
    end
    self << GemDebian.new(object) if self.select { |i| i.gemname == gem }.empty?

  end

end


