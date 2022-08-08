terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.70.0"
    }
  }


backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-vav"
    region     = "ru-central1"
    key        = "devops/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

resource "yandex_vpc_network" "net121" {
  name = "mynetwork121"
}

resource "yandex_vpc_subnet" "subnet121" {
  v4_cidr_blocks = ["10.128.0.0/24"]
  zone           = var.ZONA
  network_id     = "${yandex_vpc_network.net121.id}"
}

