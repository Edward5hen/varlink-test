#!/bin/bash
#
# ----------------------------------------------------------------
# This script is to test varlink command works well with podman.
#
# Prerequisites:
#     1. Host must be RHEL8.
#     2. Yum module container-tools is installed.
#
# Test steps:
#     1. Pull image. -->> varlink method: PullImage()
#     2. Check image is pulled. -->> varlink method: ListImages(), GetImage()
#     3. Run image. -->> varlink method: CreateContainer(), GetContainer()
#     4. Pause container. -->> varlink method: PauseContainer()
#     5. Unpause container. -->> varlink method: UnpauseContainer()
#     6. Stop container. -->> varlink method: StopContainer()
#     7. Start container. -->> varlink method: StartContainer()
#     8. Remove container. -->> valink method: RemoveContainer()
# ---------------------------------------------------------------

# ------------------------ main --------------------------------
#set -e

CMD_PREFIX="varlink call unix:/run/podman/io.podman/io.podman."

#echo "Setup: Remove all containers and images."
#podman rm -af
#podman rmi -af
#
#echo "Step1: pull image alpine and check"
#pull_result=`${CMD_PREFIX}PullImage '{"name": "alpine"}'`
#if [ "$?" -ne 0 ]; then
#    echo "Pull image alpine failed!!!"
#fi
#echo "${pull_result}"
#image_id=`echo ${pull_result} | grep -E '[[:alnum:]]{64}'`
#if [ "$?" -ne 0 ]; then
#    echo "Image ID is not printed in output!!!"
#fi

image_id="196d12cf6ab19273823e700516e98eb1910b03b17840f9d5509f03858484d321"

echo
echo "Step2-1: check image with ListImages()"
list_result=`${CMD_PREFIX}ListImages`
if [ "$?" -ne 0 ]; then
    echo "FAIL: List images failed!!!"
else
    echo "PASS"
fi
echo ${list_result} | grep "${image_id}"
if [ "$?" -ne 0 ]; then
    echo "Output of ListImages() is Wrong!!!"
else
    echo "PASS"
fi

echo
echo "Step2-2: check image with GetImage()"
get_img_result=`${CMD_PREFIX}GetImage '{"name": "docker.io/library/alpine:latest"}'`
if [ "$?" -ne 0 ]; then
    echo "FAIL: Get Image failed!!!"
else
    echo "PASS"
fi
echo ${get_img_result} | grep "${image_id}"
if [ "$?" -ne 0 ]; then
    echo "FAIL: Output of GetImage() is Wrong!!!"
else
    echo "PASS"
fi

echo
echo "Step3-1: create container with image alpine and check"
create_result=`${CMD_PREFIX}CreateContainer '{"create": {"image": "alpine", "name": "test", "command": ["/usr/bin/top"], "detach": true}}'`
if [ "$?" -ne 0 ]; then
    echo "FAIL: Create container failed!!!"
else
    echo "PASS"
fi
echo "${create_result}"
container_id=`echo ${create_result} | grep -E '[[:alnum:]]{64}'`
if [ "$?" -ne 0 ]; then
    echo "FAIL: Container ID is not printed in output!!!"
else
    echo "PASS"
fi

echo
echo "Step3-2: start container test"
start_result=`${CMD_PREFIX}StartContainer '{"name": "test"}'`
if [ "$?" -ne 0 ]; then
    echo "FAIL: Start container failed!!!"
else
    echo "PASS"
fi
echo ${start_result} | grep "${container_id}"
if [ "$?" -ne 0 ]; then
    echo "FAIL: Container id is not printed in output!!!"
else
    echo "PASS"
fi


