resource "template_file" "app_init" {
  count    = "${var.app_server_params["count"]}"
  template = "${server_name}"
  vars {
    server_name = "${format("${var.app_server_params["name"]}%02d", count.index+1)}.${var.project_tld}"
  }
}

resource "openstack_blockstorage_volume_v2" "app_vol" {
  count = "${var.app_server_params["count"]}"
  name = "disk-for-${element(template_file.app_init.*.rendered, count.index)}"
  size = "${var.app_server_params["volume_size"]}"
  volume_type = "${var.app_server_params["volume_type"]}"
  image_id = "c61cfa0d-3f7b-489f-8e55-4904a0d6e830"
  region = "${var.region}"
}

resource "openstack_compute_instance_v2" "app_instance" {
  count = "${var.app_server_params["count"]}"
  name = "${element(template_file.app_init.*.rendered, count.index)}"
  flavor_id = "${var.app_server_params["flavor"]}"
  region = "${var.region}"
  block_device {
    #uuid = "${element(${openstack_blockstorage_volume_v2.app_vol.id}, ${var.app_server_params["count"]}.index)}"
    uuid = "${element(openstack_blockstorage_volume_v2.app_vol.*.id, count.index)}"
    source_type = "volume"
    boot_index = 0
    destination_type = "volume"
  }

  metadata {
    type = "${var.app_server_params["name"]}"
  }

  network {   
    name = "${var.private_lan["name"]}"
  }
}