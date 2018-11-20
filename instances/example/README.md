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

#### 3.3) Delete the bootstrap configuration files

At this point access using the initial (potentially root) user is no longer
required and these configuration files should be removed to avoid storing any
passwords in plain text files.

Delete all of the files created during step 2 as well as `host.name.tld.bootstrap`.

#### 3.4) Create the deployment configuration files

As described in step 3.2, make a copy of the `host.name.tld.bootstrap` file for each
server. For automated `deploy` user setup described in 3.1-3.3 no further steps
are required.

If a pre-existing user account is to be used instead, edit the files accordingly 
to change the user name and point to the user's private key file.

### 4. Initialise the databases

Intake24 uses PostgreSQL version 9.6. PostgreSQL installation and configuration
is automated using Ansible.

#### 4.1 Install Ansible dependencies

From the root of the repository run:

    cd ansible
    ansible-galaxy install -r requirements.yml

#### 4.2 Get seed data snapshots

Database snapshots are currently unavailable from public sources. Contact
[Ivan Poliakov](mailto:ivan.poliakov@newcastle.ac.uk?subject=Intake24%20database%20snapshots)
to request snapshots.

#### 4.3 Edit database configuration

Edit `instances/(instance name)/database/postgres-configuration.yml`.

Fill the values in the `intake24` section:

- `admin_user_email` must be a valid e-mail address in order to receive system
notifications or reset the password. The default password is `intake24`.
- `system_database.schema_snapshot_path`, `system_database.data_snapshot_path`
and `food_database.snapshot_path` must point to the initial database snapshot
files in PostgreSQL format (see 4.2).
- Changing database names and users is optional.

#### 4.4 Run the database initialisation script

From the root of the repository run:

    ./create-databases.sh (instance name)

In case the database set up script fails after the databases have already been created the databases will need to be deleted manually to re-run the script. This is intended to prevent unintentional data loss.

Databases can be deleted by running the following commands **(on the database server, not the control machine)**, assuming default database names:

    sudo -u postgres -c "drop database intake24_system"
    sudo -u postgres -c "drop database intake24_foods"

### 5. Build and install the Intake24 API server

The Intake24 API server is mostly written in Scala and runs on the JVM.

#### 5.1 Install build dependencies

Intake24 must currently be built using JDK 8. To install it run:

    sudo apt-get install openjdk-8-jdk-headless

Intake24 uses the (SBT)[https://scala-sbt.org] build tool. To install it run the following command from root of the deployment repository:

    sudo ./build-deps/install-sbt.sh

This will add the official SBT binary repository to the system software sources and install the latest version of SBT.

#### 5.2 Clone the Intake24 API server repository

Clone the Intake24 API repository to a separate directory. **Do not clone it inside the deployment repository directory structure**:

    git clone --recurse-submodules -j8 https://github.com/intake24/api-server

#### 5.3 Build the Intake24 API server and related services

From the root of the Intake24 API server repository run:

    sbt "apiPlayServer/debian:packageBin" "dataExportService/debian:packageBin"

This process will download and install all the necessary dependencies and may take quite a while during the first run (about 20 minutes depending on your CPU speed and your Internet connection).

Following builds will be much faster.

#### 5.4 Install and configure JDK on the server

From the root of the deployment repository run:

     ./configure-java (instance name)

Make sure that the `openjdk-8-jre-headless` package is available on the server. It is not available by default on e.g. Ubuntu Server 18.04. To enable it, run the following command on the server:

    sudo add-apt-repository universe

#### 5.5 Prepare the API server configuration files

##### 5.5.1 Generate encryption key for Play Framework

In the Intake24 API repository directory, run:

    sbt apiPlayServer/playGenerateSecret

Copy the generated key (the part that follows the "Generated new secret:" message and looks like this: `zV;3:xvweW]@G5JTK7j;At<;pSj:NM=g[ALNpj?[NiWoUu3jK;K@s^a/LPf8S:5K`) and paste it into `instances/(instance name)/play-shared/http-secret.conf` in the deployment repository.

##### 5.5.2 Set up database connection URLs

Edit `instances/(instance name)/play-shared/databases.conf` and adjust PostgreSQL connection URLs if required. 

The default `localhost` URLs should work for a simple single server set up.

##### 5.5.3 Enter the SMTP details

Edit `instances/(instance name)/play-shared/play.mailer.conf` and fill out the outgoing SMTP server's details.

If left in mock mode the e-mail notifications can be found in the server's logs (e.g. `journalctl -u intake24-api-server`).

##### 5.5.4 Edit application configuration

Edit `instances/(instance name)/api-server/application.conf` and change the following:

- Set `intake24.adminFrontendUrl` to the public domain name or IP address of the administrative site (e.g. `https://admin.intake24.co.uk`)
- Set `intake24.surveyFrontendUrl` to the public domain name or IP address of the survey site (e.g. `https://intake24.co.uk`)
- Get a [reCAPTCHA key from Google](https://www.google.com/recaptcha) and set the  `recaptcha.secretKey` to the key given in the `Server side integration` section on reCAPTCHA's admin page
- (Optional) If using Intake24's short URLs service) set `intake24.shortUrlServiceUrl` to the internal IP address of the short URL service
- (Optional) If using Twilio for SMS notifications, fill out the Twilio account details in `twilio`

##### 5.5.5 Edit build paths and JVM configuration

Edit `instances/(instance name)/api-server/play-app.json`:

- Set `play_app.debian_package_path` to the path to the `.deb` package file produced by step 5.3. It can be found at `(api-server repo root)/ApiPlayServer/target/intake24-api-server_(version)_all.deb`

- (Optional) change the JVM memory settings as needed

#### 5.6 Install the API server

From the deployment repository root run:

    ./api-server.sh (instance name)