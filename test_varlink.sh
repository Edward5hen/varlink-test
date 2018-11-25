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
#     7. Remove container. -->> valink method: RemoveContainer()
#     8. Get non-exist image. -->> varlink error: ImageNotFound
#     9. Get non-exist container. -->> varlink error: ContainerNotFound
# ---------------------------------------------------------------

# ------------------------ Global Variables -------------------------
CMD_PREFIX="varlink call unix:/run/podman/io.podman/io.podman."

# ------------------------ Functions --------------------------------
verify() {
    if [ "$?" -ne 0 ]; then
        echo "FAIL: $1 failed!!!"
    else
        echo "PASS: $1 passed."
    fi
}

# ------------------------   main  ----------------------------------

echo "Setup: Remove all containers and images."
podman rm -af
podman rmi -af

echo "Step1: pull image alpine and check"
pull_result=`${CMD_PREFIX}PullImage '{"name": "alpine"}'`
verify "Pull image with PullImage()"
echo "${pull_result}"
image_id=`echo ${pull_result} | grep -E '[[:alnum:]]{64}'`
verify "Image ID print"

echo
echo "Step2-1: check image with ListImages()"
list_result=`${CMD_PREFIX}ListImages`
verify "List image with ListImages()"
echo ${list_result} | grep "${image_id}"
verify "Image id print"

echo
echo "Step2-2: check image with GetImage()"
get_img_result=`${CMD_PREFIX}GetImage '{"name": "docker.io/library/alpine:latest"}'`
verify "Get image with GetImage()"
echo ${get_img_result} | grep "${image_id}"
verify "Image ID print"

echo
echo "Step3-1: create container with image alpine and check"
create_result=`${CMD_PREFIX}CreateContainer '{"create": {"image": "alpine", "name": "test", "command": ["/usr/bin/top"], "detach": true}}'`
verify "Create container test with CreateContainer()"
echo "${create_result}"
container_id=`echo ${create_result} | grep -E '[[:alnum:]]{64}'`
verify "Container ID print"

echo
echo "Step3-2: start container test"
start_result=`${CMD_PREFIX}StartContainer '{"name": "test"}'`
verify "Start container test with StartContainer()"
echo ${start_result} | grep "${container_id}"
verify "Container ID print"

echo
echo "Step-4: pause container test"
pause_result=`${CMD_PREFIX}PauseContainer '{"name": "test"}'`
verify "Pause container test with PauseContainer()"
echo ${pause_result} | grep "${container_id}"
verify "Container id print"

echo
echo "Step-5: unpause container test"
unpause_result=`${CMD_PREFIX}UnpauseContainer '{"name": "test"}'`
verify "Unpause container test with UnpauseContainer()"
echo ${unpause_result} | grep "${container_id}"
verify "Container ID print"

echo
echo "Step-6: stop container test with timeout 5s"
stop_result=`${CMD_PREFIX}StopContainer '{"name": "test", "timeout": 5}'`
verify "Stop container test with StopContainer()"
echo ${stop_result} | grep "${container_id}"
verify "Container ID print"

echo
echo "Step-7: remove container test"
rmv_result=`${CMD_PREFIX}RemoveContainer '{"name": "test"}'`
verify "Remove container test with RemoveContainer()"
echo ${rmv_result} | grep "${container_id}"
verify "Container ID print"

echo
echo "Step-8: Get a non-exist image"
geti_result=`${CMD_PREFIX}GetImage '{"name": "non-exist"}' 2>&1`
verify "Get a non-exist image"
echo ${geti_result} | grep "ImageNotFound"
verify "Error io.podman.ImageNotFound returned"

echo
echo "Step-9: Get a non-exist container"
getc_result=`${CMD_PREFIX}GetContainer '{"name": "non-exist"}' 2>&1`
verify "Get a non-exist container"
echo ${getc_result} | grep "ContainerNotFound"
verify "Error io.podman.ContainerNotFound returned"
