#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright 2009-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "postgresql::client"

# Create a group and user like the package will.
# Otherwise the templates fail.

group "postgres" do
  gid 26
end

user "postgres" do
  shell "/bin/bash"
  comment "PostgreSQL Server"
  #  home node['postgresql']['user']['postgres']['home']
  home "/var/lib/pgsql/#{node['postgresql']['version']}"
  gid "postgres"
  system true
  uid 26
  supports :manage_home => node['postgresql']['user']['postgres']['manage_home']
end

node['postgresql']['server']['packages'].each do |pg_pack|
  package pg_pack do
    action :install
  end
end

execute "/sbin/service postgresql-#{node['postgresql']['version']} initdb" do
  not_if { ::FileTest.exist?(File.join(node.postgresql.dir, "PG_VERSION")) }
end

service "postgresql-#{node['postgresql']['version']}" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "redhat.postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql-#{node['postgresql']['version']}"), :immediately
end
