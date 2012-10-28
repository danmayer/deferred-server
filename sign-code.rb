require './lib/code-signing'
include CodeSigning

code = File.read("ruby-code.rb")
signature = code_signature(code)
puts "signature: '#{signature}'"
