#!/usr/bin/env ruby

# Load the email library
require 'mail'

# Load the smtp library
require 'net/smtp'

# Load the file utils
require 'fileutils'

class Spamalot
  def go!
    # Clear the terminal
    system("clear")

    puts "Spam-a-lot by Daniel Upton (daniel@ileopard.co)"
    puts "[Control - C] to quit"
    puts # Keep the screen tidy!

    print "SMTP server address: "
    server = gets.strip

    print "Port (usually 25, 465 or 587): "
    port = gets.strip.to_i

    print "Username: "
    username = gets.strip

    print "Password: "
    password = gets.strip

    print "Use star ttls (Y/N - Gmail usually requires it.. our server doesn't): "
    star = gets =~ /(Y|y)/

    smtp_conn = Net::SMTP.new(server, port)

    if star
      smtp_conn.enable_starttls
    end

    puts "\nConnecting (this may take a while)..."
    smtp_conn.start(server, username, password, :plain)

    Mail.defaults do
      delivery_method(:smtp_connection, { :connection => smtp_conn })
    end

    print "\nSend to: "
    send_to = gets.strip

    print "Send from: "
    send_from = gets.strip

    print "Subject: "
    subject = gets.strip

    print "Where are the files? (tip - drag and drop the folder onto the terminal): "
    directory = gets.strip

    print "Number of files at once: "
    at_once = gets.to_i

    puts "\nAnd now for something completely different.."

    # Go grab all the files in the specified directory (but ignore sub directories)
    options = Dir[File.join(File.expand_path(directory), "*")].reject {|f| File.directory?(f)}

    puts "#{options.count} files found."

    # Create a "done" directory
    done_directory = File.join(directory, "done")

    unless Dir.exists?(done_directory)
      Dir.mkdir(done_directory)
    end

    # Email the files until there's no more!
    offset = 0
    emails = 1
    while offset < options.count
      files = options[offset...(offset + at_once)]
      email(send_to, send_from, "#{subject} ##{emails}", files, done_directory)
      offset += (at_once + 1)
      emails += 1
    end
  end

  private
  def email(to, from, subject, files, done_directory)
    puts "\nPreparing '#{subject}'"
    mail = Mail.new do
      from(from)
      to(to)
      subject(subject)

      # Add the files
      files.each do |file|
        puts "Adding #{file}"
        add_file file
      end
    end

    puts "Sending..."
    mail.deliver

    puts "Cleaning up sent files."
    files.each do |file|
      FileUtils.mv(file, File.join(done_directory, File.basename(file)))
    end
  end
end

# Letsa' Go!
mailer = Spamalot.new
mailer.go!
