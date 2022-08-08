resource "yandex_compute_instance" "vm-1" {
  name = "devops-1"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu20_04
      size = "40"
    }
  }

  network_interface {
   subnet_id = "${yandex_vpc_subnet.subnet121.id}"
#   subnet_id = var.subnet
    nat       = true
  }

  metadata = {
    user-data = "${file("./usr.meta")}"
    "serial-port-enable" : "1"
  }
}
