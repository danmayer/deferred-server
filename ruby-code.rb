output_file = './artifacts/output.txt'
Dir.mkdir('./artifacts') unless File.exists?('./artifacts')

data = "math #{9 + 9} now: #{Time.now}"

File.open(output_file, 'w') {|f| f.write(data) }
puts 'done'
