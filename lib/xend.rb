require "mote"
require 'open3'
require 'xmlsimple'
require_relative 'settings'

class Xend
  include Settings
  extend Mote::Helpers

  Error = Class.new(StandardError)
  TEMPLATES = File.expand_path("../templates", File.dirname(__FILE__))

private

  def self.payload(soap, file, params)
    Curl.post(soap, 
              mote(File.join(TEMPLATES, "#{file}.xml"), params),
              "-H 'Content-Type: text/xml; charset=utf-8'")
  end

  class Rate < Xend
    def self.calculate(params)
      Response.new(payload(Settings::SOAP::RATE, "rate-calculate", params))
    end
  end

  class Shipment < Xend

    def self.get(params)
      Response.new(payload(Settings::SOAP::SHIPMENT, "shipment-get", params))
    end

  end

  class Response
    def initialize(xml)
      @data = XmlSimple.xml_in(xml)["Body"][0]
    end

    def rate
      @data["CalculateResponse"][0]["CalculateResult"][0]
    end

    def waybill
      @data["GetResponse"][0]["GetResult"][0]
    end
  end

  module Curl
    Error = Class.new(Xend::Error)

    class << self
      attr_accessor :cacert
    end

    def self.post(url, data, options = "")
      options << " --cacert '%s'" % cacert if cacert

      exec("curl -X POST --data @- #{options} #{url}", data)
    end

    def self.exec(cmd, data)
      stdout, stderr, res = Open3.capture3(cmd, stdin_data: data)

      if res.success?
        return stdout
      else
        raise Error, errors(stderr)
      end
    end

    def self.errors(stderr)
      stderr.scan(/^curl: .*$/).join("\n")
    end

  end
end