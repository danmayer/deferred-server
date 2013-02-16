require './lib/code-signing'
include CodeSigning

code = File.read("ruby-code.rb")
puts "signing code: \n'#{code.strip}' \n length #{code.strip.length}"
signature = code_signature(code)
puts "signature: '#{signature}'"
