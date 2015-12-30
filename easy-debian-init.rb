#!/usr/bin/env ruby
# encoding: UTF-8
#-------------------------------------------------------------------------
# Easy-Debian
#
# Site  : http://wiki.dksh.com.br
# Author : Douglas Q. dos Santos <douglas.dksh@gmail.com>
# Management: Douglas Q. dos Santos <douglas.dksh@gmail.com>
# GitHub: https://github.com/douglas-dksh/easy-debian
#
#-------------------------------------------------------------------------
# Note: This Ruby Script set up the initial configuration to Debian
# where install the needed packets and configure some packets
#-------------------------------------------------------------------------
# History:
#
# Version 1.0:
# Data: 29/12/2015
# Description: Set up the initial configuration of Debian GNU/Linux
# set up the repositories and install some packets
#--------------------------------------------------------------------------
#
# How to use: https://github.com/douglas-dksh/easy-debian
#
#--------------------------------------------------------------------------
#License: MIT license http://opensource.org/licenses/MIT
#--------------------------------------------------------------------------

# Used to download files
require 'open-uri'

# Used as extension of file library
require 'fileutils'

# Module that controls the colors used
module Tty extend self
def black; bold 30; end
def red; bold 31; end
def green; bold 32; end
def yellow; bold 33; end
def blue; bold 34; end
def purple; bold 35; end
def cyan; bold 36; end
def white; bold 37; end
def grey; bold 38; end
def reset; escape 0; end
def bold n; escape "1;#{n}" end
def underline n; escape "4;#{n}" end
def escape n; "\033[#{n}m" if STDOUT.tty? end
end


class Core

  # Initialize the class and check if the script is running as root user
  def initialize
    abort "#{Tty.red}Needs to run this as root!#{Tty.reset}" if Process.uid != 0
    puts "#{Tty.blue}This script is running with the following PID: #{Tty.white}"  + Process.pid.to_s + "#{Tty.reset}"
  end

  # Method to call the sleep command and wait for a given seconds
  def sleep_time(time)
    system "sleep #{time}s"
  end

  # Method to install packages
  # TODO: needs to validate if the mode is interactive or not
  def install_packages(packages,comment)
    aptitude = '/usr/bin/aptitude'
    no_interactive = 'DEBIAN_FRONTEND=noninteractive'

    puts "#{Tty.blue}Updating Repositories #{Tty.reset}"
    update_repo = system "#{aptitude} update"
    sleep_time(2)

    if update_repo
      puts "#{Tty.blue}Repositories Updated! #{Tty.reset}"
    else
      puts "#{Tty.red}Repositories Not Updated! #{Tty.reset}"
    end

    puts "#{Tty.blue}Installing Packages: #{Tty.white}#{comment} #{Tty.reset}"
    install_pkgs = system "#{no_interactive}; #{aptitude} install #{packages} -y"
    sleep_time(2)

    if install_pkgs
      puts "#{Tty.blue}Packages: #{Tty.white}#{comment} #{Tty.blue}Installed or already Installed ! #{Tty.reset}"
    else
      puts "#{Tty.red}Packages Not Installed! #{Tty.reset}"
      sleep_time(2)
    end
  end

  # Method to execute a command and return its result
  # Used to get system information such as architecture and another stuffs
  def exec_command(command)
    output = `#{command}`.chomp
    result=$?.success?
    unless result
      puts "#{Tty.red}Command with some problem! #{Tty.reset}"
    end
    # If no problems with the command line return
    return output
  end

  # Method get remote files from the github so far, but it will be extended
  # in the future.
  def download_files(path,url)
    # Check if the url is available
    result = open("#{url}", 'User-Agent' => "Ruby/#{RUBY_VERSION}")
    check_file_exits(path)
    if result.status[1] == 'OK'
      # Gets the file and save it.
      File.open("#{path}", 'w') do |saved_file|
        # the following "open" is provided by open-uri
        open("#{url}", 'User-Agent' => "Ruby/#{RUBY_VERSION}") do |read_file|
          puts "#{Tty.blue}The file: #{Tty.white}#{path} was downloaded and saved! #{Tty.reset}" if saved_file.write(read_file.read)
        end
      end
    else
      puts "#{Tty.red}The url does not exists or is Unavailable! #{Tty.reset}"
    end
  end

  # Method to create automatically backup of the files before overwrite them.
  def check_file_exits(file)
    if File.exists?(file)
      check_mv = FileUtils.move(file,"#{file}.bkp")
      check_status(check_mv,"Creating a backup of file: #{Tty.white} #{file} #{Tty.reset}")
    end
  end

  # Method to handle the keyrings, here we can update a lot of keys only sending
  # as an array.
  def conf_keyrings(url,keys=[])
    gpg = '/usr/bin/gpg'
    keys.each do |key|
      import_key = system "#{gpg} --keyserver #{url} --recv-keys #{key}"
      check_status(import_key,'Updating Keyrings')
      sleep_time(2)
    end

    apt_key='/usr/bin/apt-key'
    add_pubring = system "#{apt_key} add ~root/.gnupg/pubring.gpg"
    check_status(add_pubring,'Adding the pubring')
  end

  # Method to convert the files to unix format, in some cases we need this feature
  # so is better has a method to handle it.
  def convert_file(files=[])
    dos2unix = '/usr/bin/dos2unix'
    files.each do |file|
      convert = system("#{dos2unix} #{file}")
      check_status(convert, "Converting the file: #{file}")
    end

  end

  # Private methods that can be called only inside the Class
  private

  # Method to check the status of the commands
  def check_status(check,message)
    if check
      puts "#{Tty.blue}#{message} #{Tty.blue}executed successfully! #{Tty.reset}"
    else
      puts "#{Tty.red}#{message} #{Tty.red}executed with errors! #{Tty.reset}"
    end
  end
end

### END OF THE CORE CLASS


# Defining some paths
repositories_path = '/etc/apt/sources.list'
vimrc_path = "#{Dir.home}/.vimrc"
vimrc_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/vimrc'
rep_wheezy_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/sources-wheezy.list'

# Creating a new object to use the methods
new_deb = Core.new

# Getting the repositories
# TODO: Check the Debian Version and get the paths based on it.
new_deb.download_files(repositories_path,rep_wheezy_url)

# Defining the architecture of box
arch = new_deb.exec_command('uname -r')

# Defining the packages that needs to be installed
# TODO: Check the Debian Version and get the paths based on it.
pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring"

# Updating the keyrings
new_deb.conf_keyrings('pgpkeys.mit.edu',keys=%w(1F41B907 A2098A6E))

# Installing the packages
new_deb.install_packages(pkgs,'Base Packages')

# Defining the tool packages that needs to be installed
# TODO: Check the Debian Version and get the paths based on it.
tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm \
sdparm iotop atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'

# Installing the packages
new_deb.install_packages(tool_pkgs,'Tools Packages')

# Getting the vimrc
new_deb.download_files(vimrc_path,vimrc_url)

# Converting the file
new_deb.convert_file(files=["#{vimrc_path}"])
