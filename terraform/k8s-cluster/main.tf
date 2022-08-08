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
    key        = "k8s-cluster/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token                    = var.token
  #service_account_key_file = "path_to_service_account_key_file"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_kubernetes_cluster" "volokhov1" {
 name = var.resource_name
 network_id = yandex_vpc_network.mynetwork.id
 master {
     zonal {
     zone      = yandex_vpc_subnet.mysubnet.zone
     subnet_id = yandex_vpc_subnet.mysubnet.id
             }
    public_ip = true
 }
 service_account_id      = yandex_iam_service_account.vav.id
 node_service_account_id = yandex_iam_service_account.vav.id
   depends_on = [
     yandex_resourcemanager_folder_iam_binding.editor,
     yandex_resourcemanager_folder_iam_binding.images-puller
   ]
}

resource "yandex_kubernetes_node_group" "mynodegroup" {
  cluster_id  = "${yandex_kubernetes_cluster.volokhov1.id}"
  name        = "mynodegroup"
  description = "momo"
  version     = "1.20"
  
  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v1"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.mysubnet.id}"]
    }

    resources {
      memory = 8
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "docker"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }
}

resource "yandex_vpc_network" "mynetwork" { name = "mynetwork" }
resource "yandex_vpc_subnet" "mysubnet" {
 name           = "mysubnet"
 v4_cidr_blocks = ["10.0.0.0/24"]
 zone           = var.zone
 network_id     = "${yandex_vpc_network.mynetwork.id}"
}

resource "yandex_iam_service_account" "vav" {
 name        = "vav"
 description = "devops sa"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
 # Сервисному аккаунту назначается роль "editor".
 folder_id = var.folder_id
 role      = "editor"
 members   = [
   "serviceAccount:${yandex_iam_service_account.vav.id}"
 ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
 # Сервисному аккаунту назначается роль "admin".
 folder_id = var.folder_id
 role      = "container-registry.images.puller"
 members   = [
   "serviceAccount:${yandex_iam_service_account.vav.id}"
 ]
}
