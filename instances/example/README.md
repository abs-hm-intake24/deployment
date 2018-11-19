### 1. Install Ansible and supporting tools

    sudo apt-get install ansible sshpass

### 2. Define target host(s)

Edit `instances/(instance name)/hosts`. Replace the `host.name.tld` placeholder
with the target host names corresponding to their intended roles.

For a simple single-server installation, just replace `host.name.tld` with the
server's host name throughout the file. This can be either a symbolic name 
(like `intake24.co.uk`) or an IP address. These instructions have only been 
tested with IPv4, but IPv6 should work too.

### 3. Configure SSH access to the server(s)

The deployment scripts for Intake24 use [Ansible](https://docs.ansible.com/), 
a configuration automation tool that works over SSH. 

The remote user used by Ansible scripts can either be created manually server-side, 
or set up automatically using the steps below.

**If you'd like to use an existing or a manually created user, make sure that 
the remote user account has passwordless sudo access.** You can then skip to 3.4.

#### 3.1) Generate `deploy` user's SSH keys using ssh-keygen

For best security generate a separate key for each host or host group. 

It doesn't matter where you store them as long as the directory is reasonably 
secure.

For a simple single-server set-up with one key, from the instance configuration 
directory (e.g. `instances/main`) run:

    cd ssh
    ssh-keygen -N "" -f deploy
   

#### 3.2) Create `deploy` user on the server(s)

For each server, make a copy of the `host.name.tld.bootstrap` file in `host_vars`. 
The name should either be the server's host name or its IP address, but it must 
be the same name as the one used in the `hosts`, e.g.:

    cp host.name.tld.bootstrap 192.68.1.1

Edit the file to set the user name and authentication method that should be used 
for the initial log on and the path to the public SSH key generated in step 1.

The user must have the permission to use `sudo`. If the user does not have
passwordless sudo enabled, then an additional 

Then from the root directory of the deployment project run:

    ./create-deploy-user.sh (instance name)

Where `(instance name)` is the name of a subdirectory in `instances` describing 
an Intake24 instance.

### 3.3) Delete the bootstrap configuration files

At this point access using the initial (potentially root) user is no longer
required and these configuration files should be removed to avoid storing any
passwords in plain text files.

Delete all of the files created during step 2 as well as `host.name.tld.bootstrap`.

### 3.4) Create the deployment configuration files

As described in step 3.2, make a copy of the `host.name.tld.bootstrap` file for each
server. For automated `deploy` user setup described in 3.1-3.3 no further steps
are required.

If a pre-existing user account is to be used instead, edit the files accordingly 
to change the user name and point to the user's private key file.

### 4. Initialise the database

Intake24 uses PostgreSQL version 9.6. 