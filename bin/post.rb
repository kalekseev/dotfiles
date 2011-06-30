#!/usr/bin/env ruby
#encoding: utf-8
require "uri"
require "net/http"
require "nokogiri" if Gem::Specification::find_by_name('nokogiri')

url_open_retry_times = 3


#usps
file_with_tracking_numbers = File.expand_path(File.join(File.dirname(__FILE__), '../usps.log'))
usurl = 'http://trkcnfrm1.smi.usps.com/PTSInternetWeb/InterLabelInquiry.do'
usparams = {'origTrackNum' => 'XXXXXXXXXXXXX', 'Go to Label/Receipt Number page' => 'Go'}


unless File.readable?(file_with_tracking_numbers)
  puts "File \"#{file_with_tracking_numbers}\" not exist or not readable" 
  exit
end

array = IO.readlines(file_with_tracking_numbers)

array.each do |id|
  id.chomp!
  usparams['origTrackNum']=id
  begin
    html = Net::HTTP.post_form(URI.parse(usurl), usparams)
  rescue Exception => e
    retry if ((url_open_retry_times -= 1 ) > 0 && e.message == "Timeout::Error")
    puts e.message
    next
  end
  puts "\033[31mUSPS: #{id}\n--------------------\033[0m"
  if html.code != '200'
    puts "HTTP response not OK"
    next
  end
  found = false
  html.body.each_line do |line|
    if (line =~ /^\s+(.*)  Information, if available, is updated periodically throughout the day. Please check again later./)
      puts "\033[32m#{$1}\033[0m\n\n"
      found = true
      break
    end
  end
  puts "Item not found\n\n" unless found
end

#russian post
if Gem::Specification::find_by_name('nokogiri')

  ruurl = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'
  ruparams = {'BarCode' => 'XXXXXXXXXXXXX', 'searchsign' => '1'}

  array.each do |id|
    id.chomp!
    ruparams['BarCode'] = id
    begin
      html = Net::HTTP.post_form(URI.parse(ruurl), ruparams)
    rescue Exception => e
      retry if (url_open_retry_times -= 1 ) > 0
      puts e.message
      next
    end
    puts "\033[31mRUPOST: #{id}\n----------------------\033[0m"
    if html.code != '200'
      puts "HTTP response not OK"
      next
    end
    doc = Nokogiri.HTML(html.body, nil, 'UTF-8')
    td = doc.xpath("/html/body/form/table/tr/td[2]/div/div/table[4]/tbody/tr/td")
    if td.empty?
      puts "Item not found\n\n"
      next
    end
    just = [16,16,6,36,36,6,5,5,6,24]
    just.map! {|item| item + 1}
    names = ["status", "date", "index", "name", "attribute", 
             "weight","price","pay","index","address"]
    names.each_with_index {|n,i| print "\033[30;47m #{n.center(just[i])}\033[0m "}
    puts "\n\n"
    points = td.count/10
    points.times do |point|
      10.times do |cell|
        print "\033[30;47m #{td[point*10 + cell].inner_text.ljust(just[cell])}\033[0m "
      end
      puts
    end
    puts
  end
else
  puts "Nokogiri gem not available, install it for russia post traking"
end
