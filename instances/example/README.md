These instructions assume that the control machine, i.e. the one used to build & 
install Intake24 runs a flavour of Debian GNU/Linux. They have been tested with 
Ubuntu 18.04 both running natively and in the Windows Subsystem for Linux.

The instructions should work on macOS with minimal changes such as replacing the 
`apt-get` commands with the corresponding Homebrew or MacPorts commands.

Following instructions assume simple one-host deployment model using example
host 192.168.1.1 and nginx sites served on following ports:
- API Server - 8001
- Admin Site - 80
- Survey Site - 8000

Any of these can be deployed to own dedicated host. While you set up your hosts
in step 2, replace 192.168.1.1 accordingly (either with symbolic name or IP).
 
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

#### 3.1. Generate `deploy` user's SSH keys using ssh-keygen

For best security generate a separate key for each host or host group. 

It doesn't matter where you store them as long as the directory is reasonably 
secure.

For a simple single-server set-up with one key, from the instance configuration 
directory (e.g. `instances/main`) run:

    cd ssh
    ssh-keygen -N "" -f deploy
   

#### 3.2. Create `deploy` user on the server(s)

For each server, make a copy of the `host.name.tld.bootstrap` file in `host_vars`. 
The name should either be the server's host name or its IP address, but it must 
be the same name as the one used in the `hosts` file, e.g.:

    cp host.name.tld.bootstrap 192.68.1.1

Edit the file to set the user name and authentication method that should be used 
for the initial log on and the path to the public SSH key generated in step 1.

The user must have the permission to use `sudo`. 

Then from the root directory of the deployment project run:

    ./create-deploy-user.sh (instance name)

Where `(instance name)` is the name of a subdirectory in `instances` describing 
an Intake24 instance.

#### 3.3. Delete the bootstrap configuration files

At this point access using the initial (potentially root) user is no longer
required and these configuration files should be removed to avoid storing any
passwords in plain text files.

Delete all of the files created during step 2 as well as `host.name.tld.bootstrap`.

#### 3.4. Create the deployment configuration files

As described in step 3.2, make a copy of the `host.name.tld` file for each
server. For automated `deploy` user setup described in 3.1-3.3 no further steps
are required.

If a pre-existing user account is to be used instead, edit the files accordingly 
to change the user name and point to the user's private key file.

### 4. Initialise the databases

Intake24 uses PostgreSQL version 9.6. PostgreSQL installation and configuration
is automated using Ansible.

#### 4.1. Install Ansible dependencies

From the root of the repository run:

    cd ansible
    ansible-galaxy install -r requirements.yml

#### 4.2. Get seed data snapshots

Database snapshots are currently unavailable from public sources. Contact
[Ivan Poliakov](mailto:ivan.poliakov@newcastle.ac.uk?subject=Intake24%20database%20snapshots)
to request snapshots.

#### 4.3. Edit database configuration

Edit `instances/(instance name)/database/postgres-configuration.yml`.

Set the following values in the `intake24` section:

- `admin_user_email` must be a valid e-mail address in order to receive system
notifications or reset the password. The default password is `intake24`.
- `system_database.schema_snapshot_path`, `system_database.data_snapshot_path`
and `food_database.snapshot_path` must point to the initial database snapshot
files in PostgreSQL format (see 4.2).
- (Optional) Set the database and user names.

#### 4.4. Run the database initialisation script

From the root of the repository run:

    ./create-databases.sh (instance name)

In case the database set up script fails after the databases have already been 
created the databases will need to be deleted manually to re-run the script. This 
is intended to prevent unintentional data loss.

Databases can be deleted by running the following commands **(on the database 
server, not the control machine)**, assuming default database names:

    sudo -u postgres -c "drop database intake24_system"
    sudo -u postgres -c "drop database intake24_foods"

### 5. Build and install the Intake24 API server

The Intake24 API server is mostly written in Scala and runs on the JVM.

#### 5.1 Install build dependencies

##### 5.1.1. Java Development Kit (JDK)

Intake24 must currently be built using JDK 8. To install it run:

    sudo apt-get install openjdk-8-jdk-headless
    
**Warning**: due to [recent changes to Oracle's support strategy for the Java platform](https://www.oracle.com/technetwork/java/javase/overview/oracle-jdk-faqs.html) 
Oracle is no longer going to provide updates to older JDK versions. The above command will typically install 
an OpenJDK 8 distribution provided by the OS maintainers but it is no longer possible to ensure what exact version
is going to be installed.

**It is highly recommended to use a JDK distribution from [AdoptOpenJDK](https://adoptopenjdk.net/) instead.** 


##### 5.1.2. Scala Build Tool (SBT)
Intake24 API project uses the [SBT](https://scala-sbt.org) build tool. To install it run the 
following command from root of the deployment repository:

    sudo ./build-deps/install-sbt.sh

This will add the official SBT binary repository to the system software sources 
and install the latest version of SBT.

##### 5.1.3. Gradle build tool

Intake24 API v2 project uses [Gradle](https://docs.gradle.org/current/userguide/installation.html). Please refer to 
the tool's website for installation instructions.

#### 5.2. Clone the Intake24 API server repositories

Clone the main Intake24 API repository to a separate directory. **Do not clone it 
inside the deployment repository directory structure**:

    git clone --recurse-submodules -j8 https://github.com/intake24/api-server
    
Clone the Intake24 API v2 repository:

    git clone https://github.com/intake24/api-v2

#### 5.3. Build the Intake24 API servers and related services

##### 5.3.1. API v1 server

From the root of the Intake24 API server (`api-server`) repository run:

    sbt "apiPlayServer/debian:packageBin" "dataExportService/debian:packageBin"

This process will download and install all the necessary dependencies and may take 
quite a while during the first run (about 20 minutes depending on your CPU speed 
and your Internet connection).

Following builds will be much faster.

##### 5.3.2. API v2 server

The API v2 server build process requires access to an instance of Intake24 SQL database in order to examine the 
database schema and generate the Java definitions for database objects using [jOOQ](https://www.jooq.org/).

In the root of the API v2 project (`api-v2`) repository copy `gradle.properties.example` to `gradle.properties`.
Edit the `gradle.properties` file and set the database connection properties to point to a local instance 
of the Intake24 database.

Then run

    gradle :ApiServer:shadowJar

Which will produce a file called `api-v2/APIServer/build/libs/intake24-api-v2-(version)-all.jar`. Note the full path to 
that file to use in the deployment script. 

#### 5.4. Install and configure JDK on the server

From the root of the deployment repository run:

     ./configure-java (instance name)

This command will install and configure Java Runtime Environment version 8 from 
[AdoptOpenJDK](https://adoptopenjdk.net/).

#### 5.5. Prepare the API server configuration files

##### 5.5.1. Generate encryption key for Play Framework

In the Intake24 API repository directory, run:

    sbt apiPlayServer/playGenerateSecret

Copy the generated key (the part that follows the "Generated new secret:" message 
and looks like this: `zV;3:xvweW]@G5JTK7j;At<;pSj:NM=g[ALNpj?[NiWoUu3jK;K@s^a/LPf8S:5K`) 
and paste it into `instances/(instance name)/play-shared/http-secret.conf` in the 
deployment repository.

Paste the same key into the `authentication.jwtSecret` field in 
`instances/(instance name)/api-server-v2/service.conf`.

##### 5.5.2. Set up database connection URLs

Edit `instances/(instance name)/play-shared/databases.conf` and adjust PostgreSQL 
connection URLs if required. 

The default `localhost` URLs should work for a simple single server set up.

Edit `instances/(instance name)/api-server-v2/service.conf` and update the database 
connection URLs as above. 

##### 5.5.3. Enter the SMTP details

Edit `instances/(instance name)/play-shared/play.mailer.conf` and fill out the 
outgoing SMTP server's details.

If left in mock mode the e-mail notifications can be found in the server's logs 
(e.g. `journalctl -u intake24-api-server`).

##### 5.5.4. Edit application configuration

##### 5.5.4.1 API v1 server

Edit `instances/(instance name)/api-server/application.conf` and change the 
following:

- Set `intake24.adminFrontendUrl` to the public domain name or IP address of the 
administrative site (e.g. `https://admin.intake24.co.uk`)
- Set `intake24.surveyFrontendUrl` to the public domain name or IP address of 
the survey site (e.g. `https://intake24.co.uk`)
- Get a [reCAPTCHA key from Google](https://www.google.com/recaptcha)
(v2 Checkbox) and set the  `recaptcha.secretKey` to the key given in the
`Server side integration` section on reCAPTCHA's admin page
- (Optional) If using Intake24's short URLs service) set `intake24.shortUrlServiceUrl` 
to the internal IP address of the short URL service
- (Optional) If using Twilio for SMS notifications, fill out the Twilio account 
details in `twilio`

Edit `instances/(instance name)/api-server/nginx` and 
`instances/(instance name)/api-server/nginx.json` and update the server name.

Edit `instances/(instance name)/data-export-service/application.conf` and change the 
following:

- Set `intake24.apiServerUrl` to the public domain name or IP address of the 
API server
- Set `intake24.surveyFrontendUrl` to the public domain name or IP address of 
the survey site (e.g. `https://intake24.co.uk`)

Default setup uses AWS S3 storage to access image database. Refer to
[Using local portion size image database](https://github.com/intake24/api-server/wiki/Using-local-portion-size-image-database)
to serve image files locally.

##### 5.5.4.2 API v2 server

Edit `instances/(instance name)/api-server-v2/service.conf` and change the 
following:

- Set `authentication.jwtSecret` to the shared JWT signing key (see 5.5.1)

- (If using local file storage) Set `secureURL.local.directory` to the path where downloadable files should be stored,
e.g. `/opt/intake24/api-v2/local-files` 

- (If using local file storage) Set `secureURL.local.downloadURLPrefix` to a publicly accessible API v2 server URL,
e.g. `https://api.intake24.co.uk/v2/files` 

##### 5.5.5. Edit build paths and JVM configuration

##### 5.5.5.1. API v1 server

Edit `instances/(instance name)/api-server/play-app.json`:

- Set `play_app.debian_package_path` to the path to the `.deb` package file 
produced by step 5.3. It can be found at 
`(api-server repo root)/ApiPlayServer/target/intake24-api-server_(version)_all.deb`

- (Optional) change the JVM memory settings as needed

Edit `instances/(instance name)/data-export-service/play-app.json`:

- Set `play_app.debian_package_path` to the path to the `.deb` package file 
produced by step 5.3. It can be found at 
`(api-server repo root)/DataExportService/target/intake24-data-export_(version)_all.deb`

- (Optional) change the JVM memory settings as needed

##### 5.5.5.2. API v2 server

Edit `instances/(instance name)/api-server-v2/config.json`:

- Set `source_jar_path` to point to the JAR file produced by step 5.3.2

- (Optional) change the JVM memory settings as needed 
  
#### 5.6. Applying database migrations

- this step can be skipped if you have latest databases snapshots
- to apply a database migration, refer to [Applying database migrations](https://github.com/intake24/api-v2/wiki/Applying-database-migrations)

#### 5.7. Install the API server services

From the deployment repository root run:

    ./api-server.sh (instance name)
    ./data-export-service.sh (instance name)
    ./api-server-v2.sh (instance name)

#### 5.8. Install nginx proxy for the API server

##### 5.8.1. Install nginx

From the deployment repository root run:

    ./configure-nginx.sh (instance name)

##### 5.8.2. Prepare the nginx configuration for API server

Edit the following files:

- `instances/(instance name)/api-server/nginx-site.json`
- `instances/(instance name)/api-server/nginx-site`

Set the server names and ports as needed.

Optional SSL setup: use `nginx-site-ssl` instead of `nginx-site` template
- Delete `instances/(instance name)/api-server/nginx-site`
- Rename `instances/(instance name)/api-server/nginx-site-ssl` to
`instances/(instance name)/api-server/nginx-site`
- Set your certificate and key path details 
- Switch all external URLs in config files to point to https variant

##### 5.8.3. Create nginx site for API server

From the deployment repository root run:

    ./nginx-api-server.sh (instance name)


### 6. Build and install the Intake24 admin site

The admin site application is built automatically on the server, so this
step is straightforward.

Edit `instances/(instance name)/admin-site/app.json`

Set the host names and ports in the following fields:

- `app.http_port`
- `app.http_address`
- `app.api_base_url` (the API server's URL prefix as configured in section 5)
- `app.recaptcha.site_key` - set to the public key given in the `Client side integration` section on Google reCAPTCHA's admin page

From the deployment repository root run:

    ./admin-site.sh (instance name)

##### 6.1. Prepare the nginx configuration for Admin site

Edit the following files:

- `instances/(instance name)/admin-site/nginx-site.json`
- `instances/(instance name)/admin-site/nginx-site`

Set the server names and ports as needed.

For SSL setup, use `instances/(instance name)/admin-site/nginx-site-ssl` (step 5.7.2.).

##### 6.2 Create nginx site for Admin site

From the deployment repository root run:

    ./nginx-admin-site.sh (instance name)


### 7. Build and install the Intake24 survey site

#### 7.1 Install build dependencies

If you haven't installed the JDK yet, run:

    sudo apt-get install openjdk-8-jdk-headless

Skip this step if you have already installed it to build the API server as
explained in section 5.

Intake24 survey application uses the [Maven](https://maven.apache.org/) build 
tool. The survey feedback module is built using [npm](https://www.npmjs.com/).

 To install them run:

    sudo apt-get install maven npm

#### 7.2. Clone the Intake24 survey site repository

Clone the Intake24 survey site repository to a separate directory. **Do not 
clone it inside the deployment repository directory structure**:

    git clone --recurse-submodules -j8 https://github.com/intake24/survey-frontend

#### 7.3. Build the Intake24 survey application

From the root of the Intake24 survey site repository run:

    mvn clean install -DskipTests

The unit tests are currently out of date so they have to be skipped. Similar to
building the API server, the build tool will download the dependencies on the
first run and it will take some time.

Maven will build the application using the [GWT](http://www.gwtproject.org/)
Java to JavaScript compiler. It is highly recommended to use at least a quad
core machine for this, otherwise the GWT optimisation step can take a very
long time.

#### 7.4. Build the Intake24 survey feedback module

Run the following commands from the root of the Intake24 survey site repository:

    cd intake24feedback
    cp ./src/animate-ts/animate-base.config.ts ./src/animate-ts/animate.config.ts
    npm install
    npm run buildForPlay
    

#### 7.5. Build the Intake24 survey server

Run the following commands from the root of the Intake24 survey site repository:

    cd SurveyServer
    sbt debian:packageBin

#### 7.6. Prepare the configuration files for the survey server

Run the following command from the root of the Intake24 survey site repostitory
to generate a private key for Play Framework:

    cd SurveyServer
    sbt playGenerateSecret

Copy the generated value (that looks like `aNF<@vv@3p<Y7aZWvA0VGUa^vy!Hq?c5t9]8/sKV3a0yzm6E7duB<Rdt7sy>J<xl`), then go to the deployment repository and paste
it into `instances/(instance name)/survey-site/application.conf`.

In the same file:

- Set `intake24.internalApiBaseUrl` to the API server's host name or IP address reachable from the internal network. 
- Set `intake24.externalApiBaseUrl` to the API server's public host name or IP address reachable from the Internet.
- (Optional) Set `intake24.ga.trackingCode` to Google Analytics property code

Edit `instances/(instance name)/survey-site/play-app.json` and change the following
values:

- Set `play_app.debian_package_path` to the path to the `.deb` package file 
produced by step 7.6. It can be found at 
`(survey-frontend repo root)/SurveyServer/target/intake24-survey-site_(version)_all.deb`

- (Optional) change the HTTP listen addresses and ports

- (Optional) change the JVM memory settings as needed

#### 7.7. Install the Intake24 survey server

From the deployment repository root run:

    ./survey-site.sh (instance name) 

##### 7.8. Prepare the nginx configuration for Survey server

Edit the following files:

- `instances/(instance name)/survey-site/nginx-site.json`
- `instances/(instance name)/survey-site/nginx-site`

Set the server names and ports as needed.

For SSL setup, use `instances/(instance name)/survey-site/nginx-site-ssl` (step 5.7.2.).

##### 7.9 Create nginx site for Survey server

From the deployment repository root run:

    ./nginx-survey-site.sh (instance name)

