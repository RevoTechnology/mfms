# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mfms/version'

Gem::Specification.new do |spec|
  spec.name          = "Mfms"
  spec.version       = Mfms::Version.to_s
  spec.authors       = ["Fokin Eugene", "Ilia Stepanov"]
  spec.email         = ["e.fokin@revoup.ru", "i.stepanov"]
  spec.description   = %q{This library helps to send sms via mfms service}
  spec.summary       = %q{Send sms via mfms service}
  spec.homepage      = "https://github.com/RevoTechnology/mfms"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ["lib"]
end
