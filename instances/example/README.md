# Intake24 deployment

## Pre-requisites

### Supported Systems

Linux Ubuntu 18.04 LTS, Red Hat Linux Enterprise 7

The build will requires a minimum of 4GB of RAM and it is highly recommended that the system has at least a quad-core processor.

## Getting Started

If you're on a Red Hat based system make sure your subscription manager is registered to Red Hat

```bash
sudo subscription-manager register --username <username> --password <password> --auto-attach
```

where username and password are what you used to log onto Red Hat website.

##### Install lsb core

RHEL/CentOS:

```bash
sudo yum install redhat-lsb-core
```

Ubuntu:

```bash
sudo apt-get install lsb-core
```

##### Make sure that git is installed 

RHEL/CentOS:

Unfortunately RHEL 7 only come with git version 1.8. However, for this project we will need git to be at least 2.x

```bash
sudo yum remove git*
sudo yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.7-1.x86_64.rpm
sudo yum install git
```

Ubuntu:

```bash
sudo apt update
sudo apt install git
```

##### Clone the deployment repository

Next up you will need to clone the Intake24 deployment repository. We've forked the repository but the official repository can be found at ```https

```bash
git clone -b support/rhel https://github.com/abs-hm-intake24/deployment.git
```

##### Port and firewall configurations

Policy-core-utils (RHEL and CentOS)

Install policy-core-utils-python

```
sudo yum install policycoreutils-python
```

Now if you'd like to change the ports you'll need to edit ```port-configuration.sh``` 

```bash
sudo nano port-configuration.sh
```

In here just replace the ports within array to whatever ports you'd like to use. 

The same can be done with the public ports for the firewall at

```bash
sudo nano firewall-configuration.sh
```

From the root of the deployment directory run the below commands to set ports:

```
./port-configuration.sh
./firewall-configuration.sh
```

### Install Ansible and supporting tools

On RHEL7 or CentOS7:

```bash
sudo subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
sudo yum install ansible sshpass
```

On Ubuntu:

```bash
sudo apt-get install ansible sshpass
```

### Copy the example instance

Copy the ```instances/example``` and name the new instance to whatever you want. From the deployment directory run:

```bash
sudo cp -r instances/example instances/intake24
```

### Define target host(s)

Edit the hosts file within your instance

```bash
sudo nano /usr/share/deployment/instances/(instance name)/hosts
```

Replace all the ```host.name.tld``` with your target host names corresponding to their intended roles. For a single-server installation you can simply replace ```host.name.tld``` with the server host name through out e.g. 

![Hosts](file://C:\Users\TontrakunChaimongkol\Downloads\Hosts.PNG?lastModify=1615256685)

### Configure SSH access to the server(s)

The deployment scripts for Intake24 use Ansible which is a configuration automation tool that works over SSH.

The remote user used by Ansible scripts can either be created manually server-side, or set up automatically using the steps below.

#### Generate ```deploy``` user's SSH keys using ssh-keygen

For best security generate a separate key for each host or host group

For a simple single-server setup with one key, from ```instances/(instance name)``` run:

```bash
cd ssh
sudo ssh-keygen -N "" -f deploy
```

The keypair should be in the ssh directory where the private key is in the deploy file and the public key is in the deploy.pub

#### Create ```deploy``` user on the server(s)

For each new server you will need to make a copy of the ```host.example.tld.bootstrap``` file in ```host_vars```. The name should be either the server's host name or IP address as such it has to be the same as the one that is being used in ```hosts``` file e.g.

From the ```host_vars``` directory run:

```bash
cp host.example.tld.bootstrap 192.168.56.10
```

Now you will need to edit the newly copied file to set the username and password that will be used for the initial log on. You will also need to configured the path to the public SSH key generated in step 4.1

This user must have the permission to use sudo. Also change the python interpreter if the target machine does not have python 3.

Here is an example below: 

 ![image-20210218135421420](file://C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210218135421420.png?lastModify=1615257867)

Once that is done from the deployment directory run:

```bash
./create-deploy-user.sh (instance name)
```

### Initialise the databases

The current version of PostgreSQL that Intake24 uses is 9.6. The installation and configuration will be automated using Ansible .

##### Install ANSX.postgresql using ansible-galaxy

From deployment run:

```bash
cd ansible
ansible-galaxy install -r requirements.yml
```

*If you want ANSX.postgresql to be installed in root just run ansible-galaxy with sudo*

##### Edit database configuration

From the deployment directory:

```bash
sudo nano instances/(instance name)/database/postgres-configuration.yml
```

Change the ```admin_user_email``` to whatever you want to use to log into the admin panel. Set the ```schema_snapshot_path``` to the wherever the schema is located, ```data_snapshot_path``` to wherever the data snapshot is located and ```snapshot_path``` to wherever the foods snapshot is located at.

![image-20210309142057612](C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210309142057612.png)

Make sure to also add the deploy user as below 

![image-20210219105505455](file://C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210219105505455.png?lastModify=1613696974?lastModify=1615263827)

##### Add user postgres to sudoers

RHEL7/CentOS7:

```bash
sudo adduser -G wheel postgres
sudo passwd postgres
```

Ubuntu:

```bash
sudo adduser postgres
sudo usermod -aG sudo postgres
```

##### ANSX postgres configuration

###### Turn on logging for ```users.yml``` 

```bash
sudo nano ~/.ansible/roles/ANXS.postgresql/tasks/users.yml
```

Edit```no_log``` to false.

###### Change Postgres version to 9.6

You will need to edit the ANXS.postgresql and change the postgresql version to 9.6

```bash
sudo nano ~/.ansible/roles/ANXS.postgresql/defaults/main.yml
```

###### RHEL 7

Remove epel-release from the ansible yum install task

```bash
sudo nano ~/.ansible/roles/ANXS.postgresql/tasks/install_yum.yml
```

In the first task remove epel-release from the list

![image-20210309151424110](C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210309151424110.png)

###### Create the database

From the deployment directory run:

```bash
./create-databases.sh intake24
```

### Build and install Intake24 API Server

The Intake24 API server is mostly written in Scala and runs on the JVM

##### Install build dependencies

###### Java Development Kit

Intake24 in its current state can only be built using JDK 8. To install it run:

RHEL7/CentOS7:

```bash
sudo yum update
sudo yum install java-1.8.0-openjdk-devel
```

Ubuntu:

```bash
sudo apt update
sudo apt-get install openjdk-8-jdk-headless
```

Set ```JAVA_HOME``` path.  Bashrc is set to specific user. In our case we're setting it for the user Intake24

```bash
sudo nano /home/intake24/.bashrc
```

For root

```bash
sudo su
sudo nano ~/.bashrc
```

Inside of the .bashrc file input the below line

```bash
export JAVA_HOME=/usr/lib/jvm/java-(version)-openjdk
export PATH=$JAVA_HOME/bin:$PATH
```

Once that is done save the file and exit. Then run:

```bash
source /home/intake24/.bashrc
```

Check to see if ```JAVA_HOME``` has been set

```bash
echo $JAVA_HOME
```

###### Scala Build Tool

Intake24 API project uses SBT. Refers to [SBT](https://www.scala-sbt.org) if you need additional information. From deployment directory run:

Red Hat based systems:

```bash
sudo ./build-deps/install-sbt-yum.sh
```

Ubuntu based systems:

```bash
sudo ./build-deps/install-sbt-apt.sh
```

###### Gradle Build Tool

Intake24 API v2 project uses Gradle as such we will need to install this. 

Firstly, you will need to install unzip if you don't already have it installed

Red Hat based systems:

```bash
sudo yum install -y wget unzip
```

Ubuntu:

```bash
sudo apt-get install -y wget unzip
```

Next up we will go into the ```/tmp``` folder to download Gradle (v6.3) before unzipping it into the normal path.

```bash
cd /tmp
wget https://services.gradle.org/distributions/gradle-6.3-bin.zip
```

Extract the downloaded zip file and copy it to ```/opt/gradle``` directory.

```bash
unzip gradle-*.zip
sudo mkdir /opt/gradle
sudo cp -pr gradle-*/* /opt/gradle
```

Verify that the extracted files are there by listing the contents 

```bash
ls /opt/gradle
```

Set up the environment variables. We will first configure the profile for the PATH environment variable to include the Gradle's bin directory. Run the following command to add the environment:

```bash
echo "export PATH=/opt/gradle/bin:${PATH}" | sudo tee /etc/profile.d/gradle.sh
```

Make this profile executable by using the ```chmod``` command.

```bash
sudo chmod +x /etc/profile.d/gradle.sh
```

Load the environmental variables to the current session by using the following command:

```bash
source /etc/profile.d/gradle.sh
```

Verify the Gradle installation

```bash
gradle -v
```

 ###### Apache Maven

```bash
cd /opt
sudo wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
sudo tar xzf apache-maven-3.6.3-bin.tar.gz
sudo ln -s apache-maven-3.6.3 maven
```

Then you will need to configure the environmental variables for Maven

```
sudo nano /etc/profile.d/maven.sh
```

Within that file you will need to put these two lines

```bash
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
```

Now to load the environmental variables

```bash
source /etc/profile.d/maven.sh
```

Check the maven version by doing 

```bash
mvn -version
```

##### Clone the intake24 API server repositories

Clone the intake24 API repository to separate directory. ***Do not clone it inside the deployment repository directory structure***: 

First up currently it seems that the link to ```api-client``` is broken as such it will have to be excluded and cloned separately to all the other submodules.

In our case we just clone it into ```/usr/share``` directory

```bash
cd /usr/share
sudo git -c submodule."api-client".update=none clone -b support/rhel --recurse-submodules -j8 https://github.com/abs-hm-intake24/api-server.git
cd /usr/share/api-server
sudo git clone https://github.com/intake24/api-client.sudo nanogit
```

Within the ```api-server``` directory check to see if your current user have read and write permission. If they don't change the owner and group of all the files and folders within the directory to your current user. 

```bash
sudo chown -R USER:GROUP .
```

Once that is all done go into the ```api-server``` directory and run:

RHEL7/CentOS7:

```bash
sbt "apiPlayServer/rpm:packageBin" "dataExportService/rpm:packageBin"
```

Ubuntu: 

```bash
sudo sbt "apiPlayServer/debian:packageBin"
"dataExportService/debian:packageBin"
```

The above process will take quite awhile the first time you run it (approximately 30-40 minutes).

### Build Intake24 API-v2 

##### Clone the Intake24 api-v2 repository

Next up we will need to clone Api-v2 into ```/usr/share``` or wherever you intend on keeping APi-v2:

```bash
sudo git clone https://github.com/intake24/api-v2.git
```

##### Build API-v2

The API v2 server build process requires access to an instance of Intake24 SQL database in order to examine the database schema and generate the Java definitions for database objects using [jOOQ](![image-20210210144537655](C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210210144537655.png)) 

In the root of the API v2 project (```api-v2```) directory copy ```gradle.properties.example``` to ```gradle.properties```. Edit the ```gradle.properties``` file and set the database connection properties to a local instance of the Intake24 database.

![image-20210310115307404](C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210310115307404.png)

Go into potsgresql and create the user intake24

```bas
sudo -u postgres psql
```

Once you're inside of postgresql

```sql
ALTER USER intake24 WITH PASSWORD 'intake24';
```

Now go back to the root of the ```api-v2``` and use the command (Make sure your user has the permission to write within the api-v2 directory and its subfolders)

From the root of the ```api-v2``` directory runs:

```bash
sudo chown -R intake24:intake24 .
gradle :ApiServer:shadowJar
```

This will produce a file at```/api-v2/APIServer/build/libs/intake24-api-v2-(version)-all.jar``` 

##### Install Adopt OpenJDK JRE on the server

From the root of the deployment directory run:

```bash
./configure-java intake24
```

### Prepare the configuration files

##### Generate encryption Key for Play Framework

From the ```api-server``` directory run:

```bash
sbt apiPlayServer/playGenerateSecret
```

Once that is done you will need to take the newly generated secret key and paste it into ```instances/(instance name)/play-shared/http-secret.conf``` in place of the secret key that is currently in there. 

Then you will need to also paste it into ```authentication.jwtSecret``` field in ```instances/(instance name)/api-server-v2/service.conf``` 

Within the service.conf file change the url for the db and foods to where you want to access it from

![image-20210310121814181](C:\Users\TontrakunChaimongkol\AppData\Roaming\Typora\typora-user-images\image-20210310121814181.png)

###### Optional (SMTP) details

Edit the ```instances/(instance name)/play-shared/play.mailer.conf``  and fill out the outgoing SMTP server's details. If you do not do this you can find the server's logs by doing 

```bash
journalctl -u intake24-api-server
```

##### Edit the configuration files for API server

Edit ```instances/(instance name)/api-server/application.conf``` and change the following:

- Comment out the the line where it say ```S3StorageReadOnlyModule``` and uncomment the line below that if you're using local storage for images.

- Set ```intake24.adminFrontendUrl``` to the public domain name or IP address of the administrative site in our case it will just be 192.168.56.10:8082
- Set ```intake24.surveyFrontendUrl``` to the public domain name or IP address of the administrative site. In our case this will be 192.168.56.10:8081
- Set ```localStorage.baseDirectory``` to where the images folder is located in our case it will be ```/usr/share/intake24-images```.
- Set ```localStorage.urlPrefix``` to the public domain name or IP address of the api + images. In our case this will be 192.168.56.10:9001/images
- (Optional) Get a [reCAPTCHA key from Google]([reCAPTCHA (google.com)](https://www.google.com/recaptcha/about/)) and in the field ```v2 Checkbox``` set the ```recaptcha.secretKey``` to the key give in the server side integration section of Google's captcha's admin page. 

Edit `instances/(instance name)/api-server/nginx-site` change the following:

- Set the server listen to what ever port you want to use api server on. 
- Set the `server_name` to the public domain name or IP address in our case it will be 192.168.56.10
- Port 9001 is the standard port used for intake24. If you want to use a different API port you will need to change the port used within the c# code
- Set the `locaation /images/` to where ever you images are located `/usr/share/intake24-images`
- Set the alias to `/usr/share/intake24-images`

##### Edit the configuration files for Data Export Service

Edit ```instances/(instance name)/data-export-service/application.conf``` and change the following:

- Set ```apiServerUrl``` to the public domain name or IP address of the api server in our case it will just be 192.168.56.10:9001
- Set ```surveyFrontendUrl``` to the public domain name or IP address of the survey frontend in our case it will just be 192.168.56.10:8081

##### Edit the configuration files for Admin Site

Edit ```/usr/share/deployment/instances/(instance name)/admin-site/nginx-site``` and change the following:

- Set the listen ports to whatever ports you want the admin site to be on
- Set the ```server_name``` to the public domain name or IP address. 

Edit ```/usr/share/deployment/instances/(instance name)/admin-site/app.json/``` and change the following:

- Set the ```api_base_url``` to your public domain name or IP address of api base urI.

##### Edit the configuration files for Survey site

Edit ```/usr/share/deployment/instances/(instance name)/survey-site/application.conf``` and change the following:

- Set ```externalApiBaseUrl``` to the public domain name or IP address of the api server. In our case it will be 192.168.56.10:8001

Edit ```/usr/share/deployment/instances/(instance name)/survey-site/nginx-site```  and change the following:

- Set the listen ports to whatever ports you want the survey site to be on
- Set the ```server_name``` to the public domain name or IP address.

#### Build paths and JVM configuration

###### 6.7.5.1 API v1 Server

Edit the ```instances/(instance name)/api-server/play-app.json```:

**RHEL7/CentOS7**: 

- Change the ```debian_package_path``` to ```rpm_package_path``` then set the path to the```.rpm``` package file produced when sbt was run for API server. It should be located at ```/path/to/api-server/ApiPlayServer/target/rpm/RPMS/intake24-api-server-(version).noarch.rpm``` 

Edit ```instances/(instance name)/data-export-service/play-app.json```:

- Set the ```play_app.rpm_package_path``` to the ```.rpm``` package file produced when sbt was run for DataExportService. The file can be found at ```/path/to/api-server/DataExportService/target/intake24-data-export-(version)-all.rpm``` 

**Ubuntu**:

- Set the play_app.deb.package_path to the path of the .deb package file produced when sbt was run for API server. It should be located at ```/path/to/api-server/ApiPlayServer/target/intake24-api-server-(version)-all.deb```

Edit ```instances/(instance name)/data-export-service/play-app.json```:

- Set the ```play_app.deb_package_path``` to the ```.deb``` package file produced when sbt was run for DataExportService. The file can be found at ```/path/to/api-server/DataExportService/target/intake24-data-export_(version)_all.deb``` 

###### 6.7.5.2 API v2 Server

Edit ```instances/(instance name)/api-server-v2/config.json```:

- Set ```source_jar_path``` to point to the JAR file produced by step the ``` API-v2 build``` which is located at ```/usr/share/api-v2/APIServer/build/libs/intake24-api-v2-1.0.0-all.jar```

###### Ansible tasks for API, V2 and DataExport

From the root of the deployment directory run:

```bash
./api-server.sh (instance name)
./data-export-service.sh (instance name)
./api-server-v2.sh (instance name)
```

#### Install nginx proxy for the API server

From the root of the deployment folder run:

```bash
./configure-nginx.sh (instance name)
,/nginx-api-server.sh (instance name)
```

### Build Intake24 Admin Site

The admin site application is built automatically on the server so the step to get this working will be quite straight  forward.

Edit ```instances/(instance name)/admin-site/app.json```

Set the host names and ports in the following fields:

- ```app.http_port```
- ```app.http_address```
- ```app.api_base_url``` (The API server's URL + port)
- ```app.recaptcha.site_key``` - set to the public key given in the ```Client side integration``` section on Google reCAPTCHA's admin page (Only if you enabled reCAPTCHA)

From the deployment directory run:

```bash
./admin-site.sh (instance name)
```

##### Edit the nginx configuration files for admin site

Edit the following files:

- ```instances/(instance name)/admin-site/nginx-site.json```
  - Change the ```host_name``` to "intake24-admin"
- ```instances/(instance name)/admin-site/nginx-site```

Set the server names and ports as needed.

Once that is done in the root of the deployment directory run:

```bash
./nginx-admin-site.sh (instance name)
```

### Build Intake24 Survey Frontend

##### Clone the intake24 survey-front end repository

```bash
sudo git clone -b support/rhel --recurse-submodules -j8 https://github.com/abs-hm-intake24/survey-frontend.git
```

Make sure that javac path exists

```bash
javac -version
```

Make sure that the user that you're building with have read/write/execute permission within the survey-frontend folder. If not then run

```bash
sudo chown intake24:intake24 . -R
```

From the root of the survey-frontend directory run:

```bash
mvn clean install -DskipTests
```

##### Build the Survey Front end feedback module

From the root of the Intake24 survey site directory run:

```bash
cd intake24feedback
cp ./src/animate-ts/animate-base.config.ts ./src/animate-ts/animate.config.ts
sudo npm install
sudo npm run buildForPlay
```

You may run into issues with Insufficient entropy. This is a known issue and a fix is in the work currently. 

Next up you may run into typescript version issues when you run ```buildForPlay``` if that's the case just follow the error message and install the version of typescript that is considered to be compatible. 

Next up you will have to run a local maven install on Survey Client. 

From the `/usr/share/survey-frontend/SurveyClient` directory as root user run:

```
mvn install
```

From the root of the ```/usr/share/survey-frontend/SurveyServer``` directory as root user run:

```bash
sbt rpm:packageBin
```

##### Prepare the configuration file for the survey server

Run the following commands from the root of the ```SurveyServer``` directory to generate a private key for the Play Framework:

```
sbt playGenerateSecret
```

Copy the "Generated new secret" value and paste it into ```/usr/share/deployment/instances/(instance name)/survey-site/application.conf```

- Set ```play.cryptor.secret``` to the newly generated key
- Set ```intake24.internalApiBaseUrl``` to the API server's host name or IP address reachable from the internal network.
- Set ```intake24.externalApiBaseUrl``` to the API server's public host name or IP address reachable from the internet. 

Edit ```instances/(instance name)/survey-site/play-app.json``` and change the following values:

**RHEL**: 

Change the "debian_package_path" to "rpm_package_path"

- Set ```rpm_package_path``` to the path of the ```.rpm``` package file produced by the sbt process. This file can be found at ```/home/intake24/survey-frontend/SurveyServer/target/rpm/RPMS/noarch/intake24-survey-site-(version).noarch.rpm``` 

**Ubuntu** :

- Set the ```debian_package_path``` to the path of the .deb package file produced from the sbt process. This file can be found at ```/usr/share/survey-frontend/SurveyServer/target/intake24-survey-site_(version)_all.deb``` 

###### Install the Intake24 survey server

From the deployment directory run:

```bash
./survey-site.sh (instance name)
```

##### Prepare the nginx configuration for Survey server

Edit the following files:

- ```instances/(instance name)/survey-site/nginx-site.json```
- ```instances/(instance name)/survey-site/nginx-site```

Set the server names and ports as needed.

###### Install the nginx survey server

From the deployment directory run:

```bash
./nginx-survey-site.sh (instance name)
```

