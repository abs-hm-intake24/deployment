### Set up SSH access to servers

#### 1) Generate deploy user keys using ssh-keygen

For best security generate a separate key for each host or host group. 

It doesn't matter where you store them as long as the directory is reasonably 
secure.

For a simple single-server set-up, run:

    cd ssh
    ssh-keygen -N "" -f deploy
   

#### 2) Create deploy user on servers

For each server, make a copy of the `host.name.tld.bootstrap` file. The name 
should either be the server's host name or its IP address, but it must be the 
same name as used in the `hosts` file. 

Edit the file to set the user name that should be used for the initial log on 
and the path to the public SSH key generated in step 1.
