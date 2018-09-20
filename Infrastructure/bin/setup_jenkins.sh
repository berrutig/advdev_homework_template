#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)



#####Create a Jenkins instance with persistent storage and sufficient resources


mkdir $HOME/jenkins-slave-appdev

#oc new-project $GUID-jenkins  --display-name "Shared Jenkins"

#oc policy add-role-to-user admin ${USER} -n ${GUID}-jenkins

#oc annotate namespace ${GUID}-jenkins openshift.io/requester=${USER} --overwrite
oc project $GUID-jenkins
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi


# Deploy on DEV
cd  $HOME/jenkins-slave-appdev

echo "FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9
USER root
RUN yum -y install skopeo apb && \
    yum clean all
USER 1001"  >  $HOME/jenkins-slave-appdev/Dockerfile

######  Set up three build configurations with pointers to the pipelines in the source code project. Each build configuration needs to point to the source code repository and the respective contextDir
cd $HOME/jenkins-slave/appdev
sudo docker build . -t docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appdev:v3.9
sudo docker build . -t docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appuat:v3.9
sudo docker build . -t docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appprod:v3.9

#sudo docker login -u $GUID -p $(oc whoami -t) docker-registry-default.apps.$CLUSTER


#sudo docker push docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appdev:v3.9

#####     Create a build configuration to build the custom Maven slave pod to include Skopeo
sudo skopeo copy --dest-tls-verify=false --dest-creds=$(oc whoami):$(oc whoami -t) docker-daemon:docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appdev:v3.9 docker://docker-registry-default.apps.$CLUSTER/$GUID-jenkins/jenkins-slave-maven-appdev:v3.9


