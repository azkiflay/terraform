# Create an SSH key
resource "cherryservers_ssh" "moodle-cluster-ssh-key" {
  name       = "moodle-cluster-ssh-key"
  public_key = file("/Path_to_public_key")
}


# Create servers with identical configurations
resource "cherryservers_server" "demo-servers" {
  count      = 3 
  project_id = var.project_id
  region     = var.region
  image      = var.image
  hostname   = "demo-server-${count.index + 1}" 
  plan_id    = var.plan_id
  ssh_keys_ids = [cherryservers_ssh.terra-demo.id]  
}


# Use null_resource to wait for each server to be ready and run Ansible playbook
resource "null_resource" "run_ansible_playbook" {
  count = length(cherryservers_server.demo-servers)


  provisioner "local-exec" {
    command     = "until nc -zv ${cherryservers_server.demo-servers[count.index].primary_ip} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }


  provisioner "local-exec" {
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${cherryservers_server.demo-servers[count.index].primary_ip},' -u root --private-key //Path_to_private_key ./ansible/playbook.yml"
    working_dir = path.module
  }
}