resource_name :alfresco_services

property :resource_name, String, name_property: true
property :start_services, kind_of: [TrueClass, FalseClass], default: false

# Cookbook defaults
property :run_single_instance, kind_of: [TrueClass, FalseClass], default: lazy { node['appserver']['run_single_instance'] }
property :components, default: lazy { node['alfresco']['components'] }
property :alfresco_home, default: lazy { node['alfresco']['home'] }
property :java_home, default: lazy { node['java']['java_home'] }
property :supervisor_pidfile, String, default: lazy { node['supervisor']['pidfile'] }
property :supervisor_conffile, String, default: lazy { node['supervisor']['conffile'] }

# Tomcat instance defaults
property :tomcat_user, default: lazy { node['tomcat']['user'] }
property :tomcat_command, default: lazy { node['supervisor']['tomcat']['command'] }

# Haproxy configurations
property :haproxy_user, default: lazy { node['supervisor']['haproxy']['user'] }
property :haproxy_command, default: lazy { node['supervisor']['haproxy']['command'] }

# Nginx configurations
property :nginx_user, default: lazy { node['supervisor']['nginx']['user'] }
property :nginx_command, default: lazy { node['supervisor']['nginx']['command'] }

default_action :create

action :create do
  execute 'Stop supervisord manually' do
    command 'supervisorctl stop all'
  end

  execute 'Start supervisord manually' do
    command "supervisord -c /etc/supervisord.conf -j #{supervisor_pidfile} & sleep 3"
  end

  tomcat_instances = []

  if run_single_instance
    tomcat_instances << 'alfresco'
  else
    tomcat_instances << 'alfresco' if components.include? 'repo'
    tomcat_instances << 'share' if components.include? 'share'
    tomcat_instances << 'solr' if components.include? 'solr'
  end

  tomcat_instances.each do |server_name|
    supervisor_service "tomcat-#{server_name}" do
      action :enable
      user tomcat_user
      autorestart start_services
      autostart start_services
      directory alfresco_home
      command tomcat_command
      #  stdout_logfile 'syslog'
      #  stderr_logfile 'syslog'
      # TODO experiment with indentation & attributes
      environment 'JAVA_HOME' => java_home,
                  'CATALINA_HOME' => alfresco_home,
                  'CATALINA_BASE' => "#{alfresco_home}#{"/#{server_name}" unless run_single_instance}"
    end
  end

  supervisor_service 'haproxy' do
    action :enable
    user haproxy_user
    autorestart start_services
    autostart start_services
    command haproxy_command
    only_if { components.include? 'haproxy' }
  end

  # nginx is for the moment in alfresco-webserver
  # supervisor_service "nginx" do
  #   action :enable
  #   user nginx_user
  #   autorestart start_services
  #   autostart start_services
  #   command nginx_command
  #   only_if { components.include? 'nginx' }
  # end

  execute 'Stop supervisord manually' do
    command "cat #{supervisor_pidfile} | xargs kill -9"
    not_if { start_services }
    only_if { ::File.exist?(supervisor_pidfile) }
  end
end
