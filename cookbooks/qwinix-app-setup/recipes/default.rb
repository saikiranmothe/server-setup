# Cookbook Name:: qwinix-app-setup
# Recipe:: default
# Copyright 2014, Qwinix Technologies Pvt Ltd
# All rights reserved - Do Not Redistribute
#

# 1. Configuring the apex folder for putting all the applications
directory "/apps" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  not_if { Dir.exist?("/apps") }
end

# 2. Disable SELINUX enforcement
execute "disable selinux enforcement" do
  only_if "which selinuxenabled && selinuxenabled"
  command "setenforce 0"
  action :run
  notifies :create, "template[/etc/selinux/config]"
end

template "/etc/selinux/config" do
  source "selinux/config.erb"
  variables(
    :selinux => "disabled",
    :selinuxtype => "targeted"
  )
  action :nothing
end
#2. Configuring NTP

package 'ntp' do
action :install
end

service "ntpd" do
 action :start
end

execute "chkconfig ntpd on" do
 command "chkconfig ntpd on"
end


# 3 Wget and Malwere by Thiru
#
#
package "wget" do
  action :install
end

maldet_version = node["maldetect"]["version"]
# cd /tmp
# wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
remote_file "#{Chef::Config[:file_cache_path]}/maldetect-current.tar.gz" do
action :create
source "http://www.rfxn.com/downloads/maldetect-current.tar.gz"
checksum node["maldetect"]["checksum"]
owner "root"
group "root"
end
 
# tar xfz maldetect-current.tar.gz
execute "unpack maldetect" do
cwd Chef::Config[:file_cache_path]
command "tar xfz maldetect-current.tar.gz"
not_if {::File.directory?("#{Chef::Config[:file_cache_path]}/maldetect-#{maldet_version}")}
end
 
# cd maldetect-1.4.1/
# ./install.sh
execute "install maldetect" do
cwd "#{Chef::Config[:file_cache_path]}/maldetect-1.4.2"
command "./install.sh"
# not_if {::File.read("/usr/local/maldetect/VERSION").strip == maldet_version}
end

ruby_block "modify_line" do
  block do
    file = Chef::Util::FileEdit.new("/usr/local/maldetect/conf.maldet")
    file.search_file_replace_line("email_alert=", "email_alert=1")
    file.search_file_replace_line("email_sub=", "email_sub='Malware Detect Alert from $(hostname)'")
    file.search_file_replace_line("email_addr=", "email_addr='root@localhost'")
    file.search_file_replace_line("quar_hits=", "quar_hits=0")
    file.search_file_replace_line("quar_clean=", "quar_clean=1")
    file.write_file
  end
end


#4. Installing Logwatch
#
#
package 'logwatch' do
 action :install
end

#5. Yum update
#

execute 'yum ­-y update'
