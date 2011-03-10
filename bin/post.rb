#!/usr/bin/env ruby
require "uri"
require "net/http"

#html for russian post
#ruurl = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'
#ruparams = {'BarCode' => 'XXXXXXXXXXXXX', 'searchsign' => '1'}

file_with_tracking_numbers = File.expand_path(File.join(File.dirname(__FILE__), '../usps.log'))

usurl = 'http://trkcnfrm1.smi.usps.com/PTSInternetWeb/InterLabelInquiry.do'
usparams = {'origTrackNum' => 'XXXXXXXXXXXXX', 'Go to Label/Receipt Number page' => 'Go'}

begin
  f = File.open(file_with_tracking_numbers)
  f.each_line do |id|
    id.chomp!
    usparams['origTrackNum']=id
    html = Net::HTTP.post_form(URI.parse(usurl), usparams)
    puts "\033[31m#{id}\n--------------\033[0m"
    unless html.code == '200'
      puts "HTTP response not OK"
      next
    end
    html.body.each_line do |line|
      if (line =~ /^\s+(.*)  Information, if available, is updated periodically throughout the day. Please check again later./)
        puts "\033[32m#{$1}\033[0m\n\n"
        break
      end
    end
  end
rescue Exception => e
  puts e.message
end
