### Set up SSH access to servers

#### 1) Generate deploy user keys using ssh-keygen

For best security generate a separate key for each host or host group. 

It doesn't matter where you store them as long as the directory is reasonably 
secure.

For a simple single-server set-up, from the instance config directory run:

    cd ssh
    ssh-keygen -N "" -f deploy
   

#### 2) Create deploy user on servers

For each server, make a copy of the `host.name.tld.bootstrap` file. The name 
should either be the server's host name or its IP address, but it must be the 
same name as the one used in the `hosts` file. 

Edit the file to set the user name and authentication method that should be used 
for the initial log on and the path to the public SSH key generated in step 1.

The user must have the permission to use `sudo`.

Then from the root directory of the deployment project run:

    ./create-deploy-user.sh test

Where `test` is the name of a subdirectory in `instances` describing an Intake24 
instance.

### 3) Delete the bootstrap configuration files

At this point access using the initial (potentially root) user is no longer
required and these configuration files are no longer required.

Delete all of the files created during step 2 as well as `host.name.tld.bootstrap`.

### 4) Create the deployment configuration files

Similar to step 2, make a copy of the `host.name.tld.bootstrap` file for each
server and set the path to the SSH public key for the `deploy` user generated
in step 1.
