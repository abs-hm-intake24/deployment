## Intake24 deployment tools

### Prerequisites

#### Control machine

Intake24 control machine, responsible for running the deployment scripts and 
building the Intake24 modules, needs to be one of the following:

- Windows 10 with Windows Subsystem for Linux (WSL) enabled
- macOS
- GNU/Linux

The build process requires about 5 GB of free RAM and it is highly recommended 
that the control machine has at least a quad core processor.

The following programs are required to build and deploy all of Intake24 
components:

- Ansible
- Git
- SBT
- Maven
- Node.js

#### Intake24 backend

Intake24 backend can run on any GNU/Linux distribution using systemd, but 
Intake24 is only regularly tested on Ubuntu Server 18.04 LTS. 

Ubuntu Server 16.04 will work too with minor changes to the deployment scripts.

The complete Intake24 backend currently requires about 4 GB of RAM and is not
particularly CPU sensitive.

### Getting started

Make sure `git` is installed on the control machine, e.g.:

    sudo apt-get install git

Clone this repository:

    git clone https://github.com/intake24/deployment.git

Copy the `instances/example` directory to `instances/[short instance name]`:

    cd deployment
    cp -r instances/example instances/main

Follow the instructions in `instances/example/README.md`!
