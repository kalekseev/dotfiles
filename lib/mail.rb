#encoding: utf-8
require 'net/smtp'
require 'yaml'

MAIL_CONF = File.join(ENV['HOME'],'Dropbox/configs/mail_conf')

module Mail
  def self.send_gmail(subject, data, from="", pass="", to="")
    if from == "" or pass == "" or to == ""
      settings = YAML.load_file(MAIL_CONF)
      from = settings["bot_gmail_login"]
      pass = settings["bot_gmail_password"]
      to   = settings["user_mail"]
    end
    begin
      smtp = Net::SMTP.new 'smtp.gmail.com', 587
      smtp.enable_starttls

      message = <<EMAIL_MESSAGE
From: <#{from}>
To: <#{to}>
Subject: #{subject}
#{data}
EMAIL_MESSAGE

      smtp.start(GMAIL_SMTP,from, pass, :plain ) do |smpt|
          smtp.send_message message, from, to
      end
    rescue
      puts "Error while sending mail"
    end
  end
end
