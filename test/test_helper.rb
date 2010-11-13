require 'test/unit'
require 'shoulda'
require 'mocha'
require 'fakeweb'
require 'pp'

# FakeWeb.allow_net_connect = true
# FakeWeb.allow_net_connect = false

require File.dirname(__FILE__) + '/../lib/fgraph'

def stub_get(url, filename, status=nil)
  options = {:body => read_fixture(filename)}
  options.merge!({:status => status}) unless status.nil?
  FakeWeb.register_uri(:get, graph_url(url), options)
end

def stub_post(url, filename)
  FakeWeb.register_uri(:post, graph_url(url), :body => read_fixture(filename))
end

def stub_put(url, filename)
  FakeWeb.register_uri(:put, graph_url(url), :body => read_fixture(filename))
end

def read_fixture(filename)
  return "" if filename == ""
  File.read(File.dirname(__FILE__) + "/fixtures/" + filename)
end

def graph_url(url)
  url =~ /^http/ ? url : "http://graph.facebook.com#{url}"
end
