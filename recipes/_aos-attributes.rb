node.default['artifacts']['_vti_bin']['destination'] = "#{node['alfresco']['home']}#{'/alfresco' unless node['appserver']['run_single_instance']}/webapps"
node.default['artifacts']['ROOT']['destination'] = "#{node['alfresco']['home']}#{'/alfresco' unless node['appserver']['run_single_instance']}/webapps"
