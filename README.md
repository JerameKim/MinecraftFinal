# How to create your own Minecraft Server on EC2 using Terraform

In this tutorial we will be setting up a Minecraft Java Edition Server on an AWS EC2 instance using Terraform. Terraform will automate the networking, security and setup of the Minecraft Server EC2 instance, leaving us with a public ip address to connect to and play with our friends!

## Table of contents

- [1. Setup/Requirements](#1-setuprequirements)
- [2. Configuration Overview](#2-configuration-overview)
- [3. How to run and access the server](#3-how-to-run-and-access-the-server)
- [References](#references)

### 1. Setup/Requirements

1. Download and install the AWS CLI

   The Minecraft Server will be hosted on an Amazon EC2 instance, and will be accessed using the AWS CLI. Download and install the [AWS CLI](https://docs.aws.amazon.com/cli/). Make sure that you have ran `aws configure` and inserted your credentials before proceeding.

   Add your region and if you would like to specify a credential file, edit the provider configuration and insert the path to your own credentials file

```
// Provider config

provider "aws" {

    # TODO: Uncomment these lines and add your own region and path
    region = "us-east-1"
    # shared_credentials_files =["Your/Path/Here"]
}
```

---

2. Download and install Terraform

   We use Terraform to automate our startup, so we must have it installed on our local machine.
   Download and Install Terraform [here](https://developer.hashicorp.com/terraform/downloads).

   ***

### 2. Configuration Overview

Here we will go over the important file contents and edit the relevant configurations.

If you want to skip ahead and just install, jump to [3. How to run and access the server](#3-how-to-run-and-access-the-server) and Terraform will create the Minecraft Server in `us-east-1`.

---

1. `main.tf`

   This file contains the bulk of our work. It specifies and sets up our provider, local variables, security group, and instance.

   **Note:** Make sure to edit the AMI with one that corresponds with your region's Amazon Linux AMI. Find your AMI ID [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html).

   ```
   # Actually create the instance
   resource "aws_instance" "minecraft_server" {

       # Run the minecraft.sh file on startup of the instance.
       user_data = file("minecraft.sh")
       subnet_id = local.subnet_id

       # TODO: Specify your region's Amazon Linux AMI here
       ami = "ami-yourAMI"



       instance_type = "t2.medium"
       vpc_security_group_ids = [aws_security_group.main.id]
       tags = {
           Name = "Minecraft Final Server"
       }
   }
   ```

---

2. `minecraft.sh`

   In the Terraform file above, this bash script is ran during the first launch of the EC2 instance.

   This file first downloads Amazon's own distribution of OpenJDK called [Corretto](ttps://aws.amazon.com/corretto/?), compatible with our Amazon Linux AMI. It then creates the necessary directories and downloads Minecraft server. The URL after wget is the download link for Minecraft Server. You can make sure this link is consistent with the one found [here](https://www.minecraft.net/en-us/download/server).

   ```
   #!/bin/bash
   yum update -y
   sudo yum install -y java-17-amazon-corretto-devel.x86_64
   sudo su
   mkdir /opt/minecraft
   mkdir /opt/minecraft/server
   cd /opt/minecraft/server
   # TODO: Make sure this link is updated with the Minecraft Server download link
   wget https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar
   ```

   Next, we setup a Minecraft service and enable it. Every time this instance boots, this script will start up the Minecraft server.

   ```
   cd /etc/systemd/system/

   cat >minecraft.service<<EOF
   [Unit]
   Description=Minecraft Server
   After=network.target
   [Service]
   WorkingDirectory=/opt/minecraft/server
   ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar server.jar nogui
   Restart=always
   [Install]
   WantedBy=multi-user.target
   EOF

   chmod +xw /etc/systemd/system/minecraft.service
   sudo systemctl enable minecraft
   ```

   Finally, we agree to the [Minecraft End User License Agreement](https://aka.ms/MinecraftEULA) and run our server!

   ```
   cat >eula.txt<<EOF
   #By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).
   #Tue Jun 13 00:06:29 UTC 2023
   eula=true
   EOF
   sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
   ```

3. `outputs.tf`

   This file outputs the ID of the EC2 instance and the Public IP. This IP address will be used to connect to Minecraft Server.

4. `variables.tf`

   This configuration file is used to define two variables, vpc_id and subnet_id.

### 3. How to run and access the server

Provided that you have supplied the relevant configurations, these are the final steps to run the server.

Within the MinecraftFinal directory, intialize the Terraform project

    Terraform init

Validate the script using

    Terraform Validate

Run the Terraform script using

    Terraform apply

It will ask you `Do you want to perform these actions?`, type `yes` and continue.

Your output will look similar to:

    aws_security_group.main: Creating...
    aws_security_group.main: Creation complete after 4s [id=sg-01fa21f1aaf2186e3]
    aws_instance.minecraft_server: Creating...
    aws_instance.minecraft_server: Creation complete after 43s [id=i-034c57bf1dab3a370]
    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

    Outputs:

    instance_id = "i-034c57bf1dab3a370"
    instance_public_ip = "23.22.145.141"

After waiting a few minutes for the server to install, take the `instance_public_ip` and use this IP to join the Minecraft server. Happy mining!

## References

- Check out Keran McKenzie's [article](https://www.linkedin.com/pulse/setup-minecraft-server-java-edition-aws-ec2-keran-mckenzie) on how to set up a Minecraft server.
- The official [Minecraft Wiki](https://minecraft.fandom.com/wiki/Minecraft_Wiki) has the official, up to date information on Minecraft.
- Check out [Amazon Coretto](https://aws.amazon.com/corretto/?filtered-posts.sort-by=item.additionalFields.createdDate&filtered-posts.sort-order=desc) for more information on our JDK version.
- Minecraft also has a [DockerHub](https://hub.docker.com/r/itzg/minecraft-server/) repository if you wanted to deploy an even easier image.
- Some misc. information on [Markup](https://www.markdownguide.org/basic-syntax/#horizontal-rules) docs I used for this doc.
