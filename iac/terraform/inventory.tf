# =============================================================================
# Ansible Inventory Auto-Generation
# =============================================================================
# After terraform apply, this writes a YAML inventory file to ../ansible/inventory/
# so Ansible can pick it up immediately without manual IP transcription.
# =============================================================================

resource "local_file" "ansible_inventory" {
  filename = "${path.root}/../ansible/inventory/hosts.yml"
  content = templatefile("${path.root}/templates/inventory.yml.tpl", {
    lb_public_ip       = module.compute.lb_public_ip
    lb_private_ip      = module.compute.lb_private_ip
    teleport_public_ip = module.compute.teleport_public_ip
    teleport_private_ip = module.compute.teleport_private_ip
    kong_public_ip     = module.compute.kong_public_ip
    kong_private_ip    = module.compute.kong_private_ip
    k8s_masters        = module.compute.k8s_masters
    storage_nodes      = module.compute.storage_nodes
    platform_tools     = module.compute.platform_tools
    elk_private_ip     = module.compute.elk_private_ip
  })

  depends_on = [module.compute]
}
