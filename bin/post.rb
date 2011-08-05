#!/usr/bin/env ruby
#encoding: utf-8

require "uri"
require "net/http"
require "nokogiri"

URL_OPEN_RETRY_TIMES = 3
file_with_tracking_numbers = File.expand_path(File.join(File.dirname(__FILE__), '../usps.log'))

def get_html_body(url,params)
  i = URL_OPEN_RETRY_TIMES 
  begin
    html = Net::HTTP.post_form(URI.parse(url), params)
  rescue Exception => e
    retry if ((i -= 1 ) > 0 && e.message == "Timeout::Error")
    puts e.message
    [1,0]
  end

  if html.code != '200'
    puts "HTTP response not OK"
    [1,0]
  end

  [0, html.body]
end

def usps(array)

  usurl = 'http://trkcnfrm1.smi.usps.com/PTSInternetWeb/InterLabelInquiry.do'
  usparams = {'origTrackNum' => 'XXXXXXXXXXXXX', 'Go to Label/Receipt Number page' => 'Go'}

  array.each do |id|
    id.chomp!
    break if id !~ /.*US/
    usparams['origTrackNum']=id
    puts "\033[31mUSPS: #{id}\n--------------------\033[0m"

    (exit_code, body) = get_html_body(usurl,usparams)
    next unless exit_code == 0
    doc = Nokogiri.HTML(body, nil, 'UTF-8')
    td = doc.xpath("/html/body/table[4]/tr/td[2]/table/tr[3]/td/table/tr/td[2]/table/tr[4]/td[2]/table/tr")
    if td.empty?
      puts "Item not found\n\n"
      next
    end
    (1...td.count).each {|t| puts "\033[4;33m*\033[0m #{td[t].inner_text.lstrip.rstrip}"}
    puts

  end
end

def rupost(array)

  ruurl = 'http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo'
  ruparams = {'BarCode' => 'XXXXXXXXXXXXX', 'searchsign' => '1'}

  array.each do |id|
    id.chomp!
    ruparams['BarCode'] = id
    puts "\033[31mRUPOST: #{id}\n----------------------\033[0m"

    (exit_code, body) = get_html_body(ruurl,ruparams)
    next unless exit_code == 0

    doc = Nokogiri.HTML(body, nil, 'UTF-8')
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
end

unless File.readable?(file_with_tracking_numbers)
  puts "File with tracking numbers \"#{file_with_tracking_numbers}\" not exist or not readable"
  exit
end

array = IO.readlines(file_with_tracking_numbers)

usps(array)
rupost(array)
