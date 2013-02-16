require 'base64'
require 'openssl'

module CodeSigning

  def code_signature(code)
    code = code.strip.gsub(/(\r\n|\n|\r)/,'')
    secret = ENV['CODE_SECRET']
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, code)).gsub(/\n| |\r/, '')
  end
end

