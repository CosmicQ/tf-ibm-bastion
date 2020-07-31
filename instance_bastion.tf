data "template_file" "bastion_userdata" {
    template     = "${file("templates/instance_bastion_userdata.tpl")}"

    vars = {
      s3_access_key = "${data.external.get_secrets.result.s3_access_key.data}"
      s3_secret_key = "${data.external.get_secrets.result.s3_secret_key.data}"
      consul1       = "util-consul-1.qnix.io"
      consul2       = "util-consul-2.qnix.io"
      consul3       = "util-consul-3.qnix.io"
    }
}

resource ibm_is_instance "bastion" {
  name      = "${var.name}-bastion"
  vpc       = "${module.vpc.vpc_id}"
  zone      = "${var.zones[0]}"
  keys      = ["${var.ssh_keys}","${ibm_is_ssh_key.mykey.id}"]
  image     = "${data.ibm_is_image.default_image.id}"
  user_data = "${data.template_file.bastion_userdata.rendered}"
  profile   = "${var.bastion_profile}"

  primary_network_interface = {
    subnet          = "${module.vpc.public_subnet_ids[0]}"
    security_groups = ["${ibm_is_security_group.bastion.id}"]
  }
}
data "external" "find_current_ip" {
  program = ["bash", "scripts/current_ip.sh"]
}
resource ibm_is_floating_ip "bastion_ip" {
  name   = "${var.name}-bastion_ip"
  target = "${ibm_is_instance.bastion.primary_network_interface.0.id}"
}

# bastion_ssh
# allow IBM incoming traffic
resource ibm_is_security_group "bastion" {
  name = "${var.name}-bastion-sg"
  vpc  = "${module.vpc.vpc_id}"
}

resource "ibm_is_security_group_rule" "inbound_bastion" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "${var.bastion_ssh_ip}"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "inbound_bastion_current" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "${data.external.find_current_ip.result.ip}"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}
resource "ibm_is_security_group_rule" "inbound_bastion_consul" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "10.0.0.0/8"                       

  tcp = {
    port_min = 8301
    port_max = 8302
  }
}
resource "ibm_is_security_group_rule" "inbound_bastion_node_exporter" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "10.0.0.0/8"                       

  tcp = {
    port_min = 9100
    port_max = 9100
  }
}
resource "ibm_is_security_group_rule" "inbound_bastion_ping" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       

  icmp = {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "outbound_bastion" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"                       
}

output "current_ip" {
  value = "${data.external.find_current_ip.result.ip}"
}

output bastion_server {
  value = "${ibm_is_floating_ip.bastion_ip.address}"
}
