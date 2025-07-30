# Introduction
Server infrastructure used to be deployed and managed manually. However, that is not the case any more because manual system administration is time-consuming, error prone and cannot be scaled up to meet requirements of fast Continuous Cntegration and Continuous Deplayment (CI/CD) software delivery pipelines. Infrastructure as Code (IaC) tools fill this gap.

Terraform, developed by [HashiCorp](https://www.hashicorp.com/en), is an open-source IaC that is used to create and deploy infrastructure as code. It is widely used across cloud service providers, including Google Cloud Platform (GCP), Microsoft Azure, and Amazon Web Services (AWS). Terraform utilizes Application Programming Interfaces (APIs) of the cloud service providers to provision infrastructure such as virtual servers, databases, virtual networks, containers, load balancers, and so on. Interestingly, Terraform does all these in a re-usable few lines of code. 

Boradly, *ad hoc scripts*, *provsioning tools*, *server templating tools*, *orchestration tools*, and *configuration management tools* are considered as other methods of implementing IaC. While Terraform falls under *provisining*, it can also be used as a configuration management tool. Examples of *server templating* include Vagrant, Packer, and Docker. Kubernetes is one of the dominant tools for orchestration to define Docker containers as code, achieving high availability and scalability of infrastructure. Terraform can be combined with tools under different categories of the IaC ecosystem to define, create and orchestrate infrastrucre.

Apart from Terraform, there are other provisioning tools, including Puppet, Chef, Pulumi, Ansible, OpenStack, and CloudFormation. While each of the tools has its unique positioning in the IaC ecosystem, Terraform stands out because it is *agentless*, *masterless*, and it supports code *reusability*. Moreover, Terraform can be comined with other IaC tools such as the following. </br>
* **Terraform + Ansible**: Infrastructure provisioning using Terraform, followed by service configuration with Ansible. 
* **Packer + Terraform**: Server templating using Packer, followed by VM deployment using Terraform.
* **Packer + Kubernetes + Docker + Terraform**: Server templating of Kubernetes and Docker using Packer, followed by deployment of Kubernetes cluster using Terraform.

# Installation
In Ubuntu/Debian, Terraform can be installed using the following steps.
```bash
    # Install gnupg and software-properties-common packages 
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    # Install HashiCorp's GPG key.
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    # Verify the GPG key's fingerprint.
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint # The gpg command reports the key fingerprint
    # Add the official HashiCorp repository to your system
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    # Update apt to download the package information from the HashiCorp repository
    sudo apt update
    # Install Terraform from the new repository
    sudo apt-get install terraform
    # Verify installation
    terraform -help # Successful if you get help message from terraform.
    terraform plan -help
    # Enable tab completion
    touch ~/.bashrc
    terraform -install-autocomplete # Restart your shell to enable autocomplete
```
Installation steps for other operating systems are available [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

# Connecting Terraform with an AWS Account
* Create an IAM user on AWS with necessary permissions
* Create Access Key ID and Secret Access Key for the user
* Connect Terraform to the AWS user account by exporting the Access Key ID and Secret Access Key for the user as follows.
```bash
    # Needs to be done on very shell session.
    export AWS_ACCESS_KEY_ID = _____
    export AWS_SECRET_ACCESS_KEY = _____
```
Alternatively, the credentials can be set on AWS CLI as shown below, setting the access and secret keys long term.
```bash
    aws configure
    nano ~/.aws/credentials
```

After creating the "*.tf*" configuration file, Terraform need to scan the code, identify the provider and download the relevant code to "*.terraform*" subdirectory. Moreover, Terraform creates a "*.terraform.lock.hcl*" file to keep a record of the downloaded provider code. All these are done by issuing the "*terraform init*" command as shown below.
Terraform is init
```bash
    terraform init
```
The *init* command needs to be run to start a new Terraform code. Figure 1 shows an example output with an AWS provider.
<p align="center">
  <img src="figures/terraform_init.png" width="500" height="300"/>
</p>
<p align="center"><strong>Figure 1:</strong> Terraform initialization </p>

To run the following command, ensure to export the user credentials as shown earlier unless you are using the AWS CLI, in which case you would have set the user account details in "*~/.aws/credentials*".
```bash
    terraform plan
```
If successful, "*terraform plan*" will show you what changes will be implemented whenthe plan is enforced using "*terraform apply*". Figure 2 is a sample output of "*terraform plan*", which shows what resources will be created ("*+*" sign), deleted ("*-*") or modified ("*~*").
<p align="center">
  <img src="figures/terraform_plan.png" width="600" height="400"/>
</p>
<p align="center"><strong>Figure 2:</strong> Terraform plan </p>

In this case, an Amazon Elastic Computer Cloud (EC2) instance will be created. The actual creation of the EC2 instance occurs when "*terraform apply*" is run. 

```bash
    terraform apply
```

After displaying the actions that it will take on approval, Terraform prompts you to enter **yes** to confirm the plan. When successfully executed, "*terraform apply*" displays a message on the local machine on which Terraform is running as shown in Figure 3. Moreover, the real-world effect of the command can be observed by the creation of an EC2 instance on AWS, display to the right of Figure 3. 
<figure>
<table>
  <tr>
    <td>
      <img src="figures/terraform_apply.png" width="200" height="100"/><br>
    </td>
    <td>
      <img src="figures/terraform_apply_2.png" width="600" height="400"/><br>
    </td>
  </tr>
</table>
<figcaption><strong>Figure 3: </strong> Results of terraform apply </figcaption>
</figure>

# Terraform and Configuration Management
Terraform can work with dedicated configuration management (CM) to automate infrastructure configuration.
## On lauch setup using shell scripts
On launch, Terraform can be configured to create and instantiate infrastructed by running a shell script.

```bash
    provider "aws" {
        region = "us-east-1"
    }
    

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html 
    nohup busybox httpd -f -p 8080 & 
    EOF

    tags = { 
        Name = "moodle-instance"
        } 
    }
```

The shell script that is specified within the "*user_data*" parameter runs at launch of the instance. Similarly, software can be installed, services configured and started. Shorter scripts can be inserted using "*<<- EOF ... EOF*" as shown above. However, for long shell scripts, it is better to save them as separate files and load them to Terraform using the **file()** function.


## Ansible with Terraform

```bash
    provider "aws" {
        region = "us-east-1"
    }
    resource "aws_instance" "moodle" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash apt-get update
    apt-get install -y ansible
    echo "${file("ansible.cfg")}" > /etc/ansible/ansible.cfg
    echo "${file("hosts")}" > /etc/ansible/hosts
    EOF

    tags = { 
        Name = "moodle-instance"
        } 
    }
```
With the **ansible.cfg** and **hosts** created at the same directory as the Terrform configuration file, the function **file()** is used copy the files to the instance launched by Terraform.

Note that script passed through the *user_data* parameter is run only once during the launch of the instance. To make further changes can be made using SSH-based remote access or preferrably Ansible playbooks. Instead of storing your Ansible configuration files locally, it is a good practice to store them in a securre repository. In this way, while Terraform creates the infrastructure, Ansible automates the configuration.