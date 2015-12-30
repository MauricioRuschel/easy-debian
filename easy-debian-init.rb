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
          puts "#{Tty.blue}The file: #{Tty.white}#{path}#{Tty.blue} was downloaded and saved! #{Tty.reset}" if saved_file.write(read_file.read)
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

  # Method to create automatically backup of the files before overwrite them.
  def check_dir_exits(dir)
    if Dir.exists?(dir)
      check_mv = FileUtils.move(dir,"#{dir}.bkp")
      check_status(check_mv,"Creating a backup of directory: #{Tty.white} #{dir} #{Tty.reset}")
    end
  end

  # Method to handle the keyrings, here we can update a lot of keys only sending
  # as an array.
  def conf_keyrings(url,keys=[])
    gpg = '/usr/bin/gpg'
    keys.each do |key|
      import_key = system "#{gpg} --keyserver #{url} --recv-keys #{key}"
      check_status(import_key,"Updating #{Tty.white}#{key}#{Tty.blue} in the Keyring")
      sleep_time(2)
    end

    apt_key='/usr/bin/apt-key'
    add_pubring = system "#{apt_key} add ~root/.gnupg/pubring.gpg"
    check_status(add_pubring,'Adding the pubring')
  end

  # Method to convert the files to unix format, in some cases we need this feature
  # so is better has a method to handle it.
  def convert_file(files=[])
    dos2unix = '/usr/bin/dos2unix -q'
    files.each do |file|
      convert = system("#{dos2unix} #{file}")
      check_status(convert, "Converting the file: #{Tty.white}#{file}#{Tty.blue}")
    end
  end

  # Method to configure the crontab
  def conf_crontab(path)
    crontab = '/usr/bin/crontab'
    bkp_crontab = system("#{crontab} -l > crontab.bkp")
    check_status(bkp_crontab, "Creating backup of #{Tty.white}crontab#{Tty.blue} file")
    remove_crontab = system("#{crontab} -r")
    check_status(remove_crontab, "Removing the #{Tty.white}crontab#{Tty.blue} configuration")
    add_crontab = system("#{crontab} #{path}")
    check_status(add_crontab, "Adding the new #{Tty.white}crontab#{Tty.blue} configuration")
  end

  # Method to get git repositories
  def get_git(path,url,comment,copy)
    git = '/usr/bin/git'
    cp = '/bin/cp'
    check_dir_exits(path)
    check_git = system("#{git} clone #{url} #{path}")
    check_status(check_git, "Cloning the #{Tty.white}#{comment}#{Tty.reset}")
    if !copy.empty?
        if Dir.exists?(copy)
          copy_repo = system("#{cp} -Rfa #{path}/* #{copy}")
          check_status(copy_repo, "Copying the #{Tty.white}#{comment} #{Tty.blue}to #{Tty.white} #{copy} ")
        else
          puts "#{Tty.red}The directory #{Tty.white}#{copy} #{Tty.red}does not exists!#{Tty.reset}"
        end
    end
  end

  # Method to get the OS version, it will be used for the another scripts
  def check_os_version(os)
    cat = '/bin/cat'
    debian_version = '/etc/debian_version'
    centos_version = '/etc/redhat-relase'

    os_availables = %w(debian centos)
    if os_availables.include?(os.downcase)
      if os == 'debian'
        if File.exists?(debian_version)
          os_version = `#{cat} #{debian_version}`.chomp[/\d+/]
          case os_version
            when '6'
              return os_version_name = 'squeeze'
            when '7'
              return os_version_name = 'wheezy'
            when '8'
              return os_version_name = 'jessie'
            else
              puts "#{Tty.red}The Debian given does not have support yet! #{Tty.reset}"
          end
        else
          puts "#{Tty.red}The #{Tty.white}#{debian_version}#{Tty.red} does not exists! #{Tty.reset}"
        end
      elsif os == 'centos'
        if File.exists?(centos_version)
          os_version_name = `#{cat} #{centos_version}`.chomp[/\d+/]
        else
          puts "#{Tty.red}The #{Tty.white}#{centos_version}#{Tty.red} does not exists! #{Tty.reset}"
        end
      end
    else
      puts "#{Tty.red}The OS given does not have support yet! #{Tty.reset}"
    end
    return os_version_name
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

# GLOBAL Variables
os_version = 'debian'

# Creating a new object to use the methods
new_deb = Core.new

# Check the os Version
os_version_name = new_deb.check_os_version("#{os_version}")

# Defining some paths
repositories_path = '/etc/apt/sources.list'
vimrc_path = "#{Dir.home}/.vimrc"
bashrc_root_path = "#{Dir.home}/.bashrc"
bashrc_common_path = "/etc/skel/.bashrc"
crontab_path = '/tmp/crontab'
firmware_path = '/usr/src/firmware'
firmware_copy_path = '/lib/firmware/'

# Defining some urls
debian_rep_url = "https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/sources-#{os_version_name}.list"
vimrc_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/vimrc'
bashrc_root_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/bashrc_root'
bashrc_common_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/bashrc_common'
crontab_url = 'https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/crontab'
firmware_url = 'git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git'

# Getting the repositories
new_deb.download_files(repositories_path,debian_rep_url)

# Defining the architecture of box
arch = new_deb.exec_command('uname -r')

# Defining the packages that needs to be installed
case os_version_name
  when 'squeeze'
    pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring"
  when 'wheezy'
    pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring"
  when 'jessie'
    pkgs = "vim vim-scripts vim-doc zip unzip rar p7zip bzip2 less links telnet locate openssh-server sysv-rc-conf \
rsync build-essential linux-headers-#{arch} libncurses5-dev ntpdate postfix cmake sudo git makepasswd debian-archive-keyring"
end

# Updating the keyrings
new_deb.conf_keyrings('pgpkeys.mit.edu',keys=%w(1F41B907 A2098A6E 65558117))

# Installing the packages
new_deb.install_packages(pkgs,'Base Packages')

# Defining the tool packages that needs to be installed
case os_version_name
  when 'squeeze'
    tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm fish \
sdparm atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'
  when 'wheezy'
    tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm fish \
sdparm atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'
  when 'jessie'
    tool_pkgs = 'atsar tcpstat ifstat dstat procinfo pciutils dmidecode htop nmap tcpdump usbutils strace ltrace hdparm fish \
sdparm atop iotop iftop sntop powertop itop kerneltop dos2unix tofrodos chkconfig zsh xz-utils unrar libjs-jquery arp-scan'
end

# Installing the packages
new_deb.install_packages(tool_pkgs,'Tools Packages')

# Getting the vimrc
new_deb.download_files(vimrc_path,vimrc_url)

# Getting the bashrc configuration file
new_deb.download_files(bashrc_root_path,bashrc_root_url)
new_deb.download_files(bashrc_common_path,bashrc_common_url)

# Getting the crontab configuration file
new_deb.download_files(crontab_path,crontab_url)

# Configuring the crontab
new_deb.conf_crontab(crontab_path)

# Converting the file
new_deb.convert_file(files=["#{vimrc_path}","#{bashrc_root_path}","#{bashrc_common_path}"])

# Getting the new firmwares
new_deb.get_git(firmware_path,firmware_url,'Kernel Firmwares',firmware_copy_path)