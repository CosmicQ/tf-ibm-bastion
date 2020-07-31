#cloud-config
manage_etc_hosts: false
package_upgrade: false
disable_root: false

runcmd:
- 'sed -i ''s/mirrors.adn.networklayer.com/mirrors.tripadvisor.com/g'' /etc/yum.repos.d/*.repo'
- 'yum -y update'
- 'yum -y install nmap-ncat net-tools bind-utils screen ntp wget unzip'
- 'ntpdate 161.26.0.6'
- 'echo "######################################"'
- 'echo "# Setup AWS CLI"'
- 'curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py'
- 'python get-pip.py'
- 'pip --quiet install awscli'
- 'mkdir -p /root/.aws'
- 'echo [default] > /root/.aws/credentials'
- 'echo aws_access_key_id = ${s3_access_key} >> /root/.aws/credentials'
- 'echo aws_secret_access_key = ${s3_secret_key} >> /root/.aws/credentials'
- 'echo "######################################"'
- 'echo # Install Consul'
- 'aws --endpoint-url=https://s3.us-south.cloud-object-storage.appdomain.cloud s3 cp s3://resilient-artifacts/consul/install_consul.sh /root/'
- '/bin/bash /root/install_consul.sh agent'
- 'echo "######################################"'
- 'echo # Install Node Exporter'
- 'aws --endpoint-url=https://s3.us-south.cloud-object-storage.appdomain.cloud s3 cp s3://resilient-artifacts/exporter/node/install_node_exporter.sh /root/'
- '/bin/bash /root/install_node_exporter.sh'

final_message: "The system is finally up, after $UPTIME seconds"