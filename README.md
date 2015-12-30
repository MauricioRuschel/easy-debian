# Easy-Debian

> **Note:** This repository contains the core code of easy-debian scripts.

### How do I get set up? ###

* Summary of set up
* Configuration
* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

## Easy-Debian

Easy-Debian is a Ruby script that can help you to up and running with Debian GNU/Linux easily and install and configure some features such as repositories, essential packages that help us with the Debian administration, crontab basic configuration, vim theme, basic bashrc configuration and update the firmwares from the kernel git repository.

## How to use

You can install the **curl** package in your Debian GNU/Linux and execute the following command line as root user

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/easy-debian-init.rb)"
```

You can also download the easy-debian-init.rb and execute it via command line as root user as following
````bash
wget -c https://raw.githubusercontent.com/douglas-dksh/easy-debian/master/easy-debian-init.rb
```

Give the easy-debian-init.rb execution permission
````bash
chmod +x easy-debian-init.rb
```
After that you can execute the Ruby script as following
````bash
./easy-debian-init.rb
```
If you are working behind a proxy server you need to initialize the the class with proxy parameters change the instance in the line 331
```ruby
[...]
# Creating a new object to use the methods
# Usage examples:
# Without proxy
# new_deb = EasyDebian::Core.new()
# Using only server and port for proxy connection
# new_deb = EasyDebian::Core.new("10.0.0.254", "3128")
# Using server, port, user and password for proxy connection
# new_deb = EasyDebian::Core.new("<http proxy URL>", "<port >", "Proxy user name", "Proxy Password")
new_deb = EasyDebian::Core.new()
```

## Version
This is the beta version yet and I am working to improve and add some new features and this version is working properly.

The current version support the following Debian GNU/Linux Versions
* Squeeze
* Wheezy
* Jessie

## Security Vulnerabilities

If you discover a security vulnerability within easy-debian, please send an e-mail to Douglas Quintiliano dos Santos at douglas.dksh@gmail.com. All security vulnerabilities will be promptly addressed.

### License

The easy-debian scripts are open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT).
