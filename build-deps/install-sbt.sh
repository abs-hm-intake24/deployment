#echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
#apt-get update
#apt-get install sbt

curl https://bintray.com/sbt/rpm/rpm |sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
sudo yum install sbt
