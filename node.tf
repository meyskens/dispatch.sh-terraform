variable "nodes" {
    default = 3
}

resource "scaleway_ip" "k8s-node-ip" {
  count = "${var.nodes}"
}

resource "scaleway_server" "k8s-node" {
  count     = "${var.nodes}"
  name      = "k8s-node-${count.index + 1}"
  image     = "${data.scaleway_image.centos.id}"
  type      = "ARM64-2GB"
  public_ip = "${element(scaleway_ip.k8s-node-ip.*.ip, count.index)}"
  enable_ipv6 = true

  connection {
    type = "ssh"
    user = "root"
    timeout = "30m"
    private_key = "${file("/home/user/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "files/repos/kubernetes.repo"
    destination = "/etc/yum.repos.d/kubernetes.repo"
  }

  provisioner "remote-exec" {
    inline = [
        "setenforce 0",
        "systemctl stop firewalld",
        "systemctl disable firewalld",
        "sysctl net.bridge.bridge-nf-call-iptables=1",
        "yum -y update",
        "yum -y install docker",
        "systemctl enable docker",
        "systemctl start docker",
        "yum install -y kubelet kubeadm kubectl",
        "systemctl enable kubelet",
        "systemctl start kubelet",
        "${data.external.kubeadm-join.result.command}",
    ]
  }
}