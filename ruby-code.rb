output_file = './artifacts/output.txt'
data = "math #{9 + 9} now: #{Time.now} hooray"
File.open(output_file, 'w') {|f| f.write(data) }
