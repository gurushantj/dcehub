#!/usr/bin/env bash

echo "Command format should be like  \"sh masterBuild.sh git_user_name git_password dockerImageCommitId localDockerImageRegIp localDockerImageRegPort\""

if [ -z "$1" ]
then
  echo "git user name is not passed"
  exit 1
fi

if [ -z "$2" ]
then
  echo "git user password is not passed"
  exit 1
fi

if [ -z "$3" ]
then
  echo "docker image commitId is not passed"
  exit 1
fi

if [ -z "$4" ]
then
  echo "docker registry ip is not passed"
  exit 1
fi

if [ -z "$5" ]
then
  echo "docker registry port is not passed"
  exit 1
fi


gitUserName=$1
gitUserPwd=$2
dockerImageCommitId=$3
localDockerImageRegIp=$4
localDockerImageRegPort=$5

install_fluir_packages()
{
### Install required packages###
echo "Installing packages ..."
add-apt-repository -y ppa:openjdk-r/ppa
apt-get  update
apt-get install -y openjdk-8-jdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
rm -f /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/profile.d/jdk.sh
echo "export PATH=$PATH:$JAVA_HOME/bin" >> /etc/profile.d/jdk.sh
apt-get remove -y scala-library scala
wget www.scala-lang.org/files/archive/scala-2.11.8.deb
dpkg -i scala-2.11.8.deb
rm -rf scala-2.11.8.deb
echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
apt-get update
apt-get install -y sbt
apt install -y maven
apt install -y npm
}


build_ganeshaHDFS()
{
export DCEFS_VERSION=1.0
rm -rf /usr/local/dcefs-pkgs
cd /root/ganeshaHDFS && rm -rf /root/ganeshaHDFS/dce-fs/libs/libdcefs.so && sh build_deb.sh 0 && sh build_deb.sh 1 && cd -
if [ -f "/root/ganeshaHDFS/dce-fs/libs/libdcefs.so" ]
then
  echo "********************************Successfuly built ganeshahdfs********************************"
else
  echo "********************************Build failed ganeshahdfs********************************"
  exit 1
fi
cp /root/ganeshaHDFS/dcefs-pkgs/dcefs*.deb /root/spark-jobserver/deployment/docker-commons/dcefs/
echo "dcefs="$DCEFS_VERSION >> $VERSION_INFO_FILE

tar xvzf /root/ganeshaHDFS/scripts/libsparkfs-packages-*
sparkfs=libsparkfs-packages-*
sparkfs_version=$(echo $sparkfs | awk -F- '{print $3}')
sparkfs_version1=$(echo $sparkfs | awk -F- '{print $4}')
sparkfs_version=$sparkfs_version"-"$sparkfs_version1
dce_vu=$(ls $sparkfs/libdcevu*.deb | head -1)
dce_vu_version=$(echo $dce_vu | awk -F_ '{print $2}')
echo "sparkfs_version=$sparkfs_version-$dce_vu_version" >> $VERSION_INFO_FILE
}

build_fluir_image()
{
cd /root/spark_mirror && mvn validate && cd -
echo "Building fluir images ..."
cd /root/spark-jobserver/deployment && sh build.sh && cd -
echo "Built fluir images ..."
}

push_fluir_image()
{
###Pusing images to the local registry###
echo "Pushing image to registry"
cd /root/DCEServices/plugins/fluirengine/scripts && sh push-images-to-registry.sh $localDockerImageRegIp $localDockerImageRegPort $dockerImageCommitId&& cd -
echo "Pushed image to registry"
}

build_and_push_dceservice_image()
{
echo "Building dceservice image"
cp $VERSION_INFO_FILE /root/DCEServices/container/dceservices/
cd /root/DCEServices/container && sh build_image.sh
git_tag=$(git rev-parse --short=12 HEAD)
docker tag bigdatalabs/dceservices:$git_tag $localDockerImageRegIp:$localDockerImageRegPort/bigdatalabs/dceservices:$git_tag
docker push $localDockerImageRegIp:$localDockerImageRegPort/bigdatalabs/dceservices:$git_tag
docker image remove $localDockerImageRegIp:$localDockerImageRegPort/bigdatalabs/dceservices:$git_tag
echo "Pushed image to registry"
}


#Function call to the above methods
build_ganeshaHDFS
install_fluir_packages
build_fluir_image
push_fluir_image  $localDockerImageRegIp $localDockerImageRegPort $dockerImageCommitId
build_and_push_dceservice_image