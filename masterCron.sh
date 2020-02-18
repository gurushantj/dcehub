#!/usr/bin/env bash

cd /root
rm -rf spark-jobserver/ DCEServices/ spark_mirror/ ganeshaHDFS/
echo "rm -rf is successfull ..."
> /root/cron_logs/cron_jobs.log
> /root/cron_logs/cron_fail.log
echo "Cron job log file cleanup is successfull ..."
gitUserName=ruhan09
gitUserPwd=*Ruhan09

export VERSION_INFO_FILE=versionInfo
> $VERSION_INFO_FILE

clone_git_repo()
{
echo "Installed packages ..."
### clone required codebases ###
echo "Cloning repos ..."
git clone -b master https://$gitUserName:$gitUserPwd@github.com/DCEngines/ganeshaHDFS.git
git clone -b dce_master https://$gitUserName:$gitUserPwd@github.com/DCEngines/spark_mirror.git
git clone -b fluir_master https://$gitUserName:$gitUserPwd@github.com/DCEngines/spark-jobserver.git
git clone -b sp_integration https://$gitUserName:$gitUserPwd@github.com/DCEngines/DCEServices.git
git clone -b master https://$gitUserName:$gitUserPwd@github.com/DCEngines/DCEngines/splash_mirror.git
echo "Clonined repos ..."
echo "Building ganeshaHDFS ..."
}

clone_git_repo $gitUserName $gitUserPwd

cd /root/spark-jobserver
#dockerImageCommitId=0.2-$(git log --format="%H" -n 1)
dockerImageCommitId=0.2-test

echo "Commit ID: $dockerImageCommitId";
echo "fluirimageversion=$dockerImageCommitId" >> $VERSION_INFO_FILE
sh /root/master_cron_script.sh ruhan09 *Ruhan09 $dockerImageCommitId 172.21.75.221 5000
docker rmi $(docker images|grep none)
#Script has ended
