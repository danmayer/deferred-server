require 'pdfkit'

kit = PDFKit.new('http://resume.mayerdan.com/')
Dir.mkdir('./artifacts') unless File.exists?('./artifacts')
file = kit.to_file('./artifacts/temp_pdf_kit.pdf')
puts 'done'
