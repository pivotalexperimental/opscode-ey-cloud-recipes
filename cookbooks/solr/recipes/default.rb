#
# Cookbook Name:: solr
# Recipe:: default
#

require 'digest/sha1'

node[:applications].each do |app,data|

  directory "/data/#{app}/jettyapps" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    recursive true
  end
  
  directory "/var/run/solr" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    recursive true
  end
  
  directory "/data/#{app}/shared/solr/data" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    action :create
    recursive true
  end
  
  directory "/data/#{app}/jettyapps/solr/logs" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0777
  end
  
  directory "/data/#{app}/current/solr" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    recursive true
  end
  
  link "/data/#{app}/current/solr/#{node[:environment][:framework_env]}" do
    to "/data/#{app}/shared/solr/data"
  end

  link "/data/#{app}/jettyapps/solr/solr/conf/schema.xml" do
    to "/data/#{app}/current/vendor/plugins/acts_as_solr/solr/solr/conf/schema.xml"
  end

  link "/data/#{app}/jettyapps/solr/solr/conf/solrconfig.xml" do
    to "/data/#{app}/current/vendor/plugins/acts_as_solr/solr/solr/conf/solrconfig.xml"
  end
  
  link "/data/#{app}/shared/pids" do
    to "/data/#{app}/current/tmp/pids"
  end

  template "/engineyard/bin/solr" do
    source "solr.erb"
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    variables({
      :rails_env => node[:environment][:framework_env]
    })
  end

  template "/etc/monit.d/solr.#{app}.monitrc" do
    source "solr.monitrc.erb"
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    variables({
      :app => app,
      :owner_name => node[:owner_name]
    })
  end

  execute "install solr example package" do
    command("if [ ! -e /data/#{app}/jettyapps/solr ]; then cd /data/#{app}/jettyapps && " +
            "wget -O apache-solr-1.3.0.tgz http://mirror.cc.columbia.edu/pub/software/apache/lucene/solr/1.3.0/apache-solr-1.3.0.tgz && " +
            "tar -xzf apache-solr-1.3.0.tgz && " +
            "mv apache-solr-1.3.0/example solr && " + 
            "rm -rf apache-solr-1.3.0; fi")
    action :run
  end
  
  execute "restart-monit-solr" do
    command "sudo /usr/bin/monit reload && " +
            "sudo /usr/bin/monit restart all -g solr_#{app}"
    action :run
  end

end
