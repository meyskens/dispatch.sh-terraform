resource "scaleway_ip" "k8s-master-ip" {
  count = 1
}

resource "scaleway_server" "k8s-master" {
  count     = 1
  name      = "k8s-master-${count.index + 1}"
  image     = "${data.scaleway_image.centos.id}"
  type      = "ARM64-2GB"
  public_ip = "${element(scaleway_ip.k8s-master-ip.*.ip, count.index)}"
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

  provisioner "file" {
    source      = "files/manifests"
    destination = "/tmp/"
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
        "kubeadm init --apiserver-advertise-address=${self.private_ip} --apiserver-cert-extra-sans=${self.public_ip} --pod-network-cidr=10.244.0.0/16",
        "mkdir -p $HOME/.kube",
        "cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "chown $(id -u):$(id -g) $HOME/.kube/config",
        "kubectl apply -f /tmp/manifests/flannel.yaml",
        "kubectl apply -f /tmp/manifests/dashboard-rbac.yaml",
        "kubectl apply -f /tmp/manifests/dashboard.yaml",
    ]
  }
}


data "external" "kubeadm-join" {
  program = ["./scripts/get-token.sh"]

  query = {
    host = "${scaleway_ip.k8s-master-ip.0.ip}"
  }

  depends_on = ["scaleway_server.k8s-master"]
}