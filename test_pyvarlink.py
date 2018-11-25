#!/usr/bin/python3

"""
Test script with unitttest to verify pthon3-varlink package work well
with podman.

Prerequisites:
    1. Host must be RHEL8.
    2. Yum module container-tools is installed.

Test steps:
    1. Pull image. -->> varlink method: PullImage()
    2. Check image is pulled. -->> varlink method: ListImages(), GetImage()
    3. Run image. -->> varlink method: CreateContainer(), GetContainer()
    4. Pause container. -->> varlink method: PauseContainer()
    5. Unpause container. -->> varlink method: UnpauseContainer()
    6. Stop container. -->> varlink method: StopContainer()
    7. Start container. -->> varlink method: StartContainer()
    8. Remove container. -->> valink method: RemoveContainer()
    9. Remove image. -->> varlink method: RemoveImage(), GetImage()
    10. Get a non-exist image. -->> varlink error: ImageNotFound
    11. Get a non-exist container. -->> varlink error: ContainerNotFound
"""

import argparse
import unittest
import subprocess
import time

import varlink
from varlink import VarlinkError


class TestPyVarlink(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        addr = "unix:/run/podman/io.podman"
        interface = "io.podman"

        # Delete all containers
        subprocess.call('podman rm -af', shell=True)
        # Delete all images
        subprocess.call('podman rmi -af', shell=True)

        try:
            cls._client = varlink.Client.new_with_address(addr)
            cls.conn = cls._client.open(interface, namespaced=True)
        except varlink.ConnectionError as e:
            print("ConnectionError:", e)
            raise e
        except varlink.VarlinkError as e:
            print(e)
            print(e.error())
            print(e.parameters())
            raise e

    def _check_ctn_status(self):
        # Check container running states
        return self.conn.GetContainer('test').container.status

    def test_a_pull(self):
        self.assertEqual(len(self.conn.PullImage('alpine:latest').id), 64)
        time.sleep(3)

    def test_b_images_list(self):
        self.assertEqual(self.conn.ListImages().images[0].repoTags,
                         ['docker.io/library/alpine:latest'])

    def test_c_get_image(self):
        self.assertIsNotNone(self.conn.GetImage('docker.io/library/alpine:latest'))
        self.assertRaises(varlink.VarlinkError, self.conn.GetImage, 'somethingNotExist')

    def test_d_run_image(self):
        # Due to bugzilla 1648300, this test step is implemented by shell command
        exit_code = subprocess.call('podman run -d --name test alpine /usr/bin/top', shell=True)
        self.assertEqual(exit_code, 0)
        time.sleep(3)

        self.assertEqual(self._check_ctn_status(), 'running')

    def test_e_list_containers(self):
        self.assertEqual(self.conn.ListContainers().containers[0].names,
                         'test')

    def test_f_get_container(self):
        self.assertIsNotNone(self.conn.GetContainer('test'))
        self.assertRaises(varlink.VarlinkError, self.conn.GetContainer, 'somethingNotExist')

    def test_g_pause_container(self):
        self.assertEqual(len(self.conn.PauseContainer('test').container), 64)
        time.sleep(3)
        self.assertEqual(self._check_ctn_status(), 'paused')

    def test_h_unpause_container(self):
        self.assertEqual(len(self.conn.UnpauseContainer('test').container), 64)
        time.sleep(3)
        self.assertEqual(self._check_ctn_status(), 'running')

    def test_i_stop_container(self):
        self.assertEqual(len(self.conn.StopContainer('test').container), 64)
        time.sleep(10)
        self.assertEqual(self._check_ctn_status(), 'exited')

    def test_j_start_container(self):
        self.assertEqual(len(self.conn.StartContainer('test').container), 64)
        time.sleep(3)
        self.assertEqual(self._check_ctn_status(), 'running')

    def test_k_remove_container_force(self):
        self.assertEqual(len(self.conn.RemoveContainer('test', True).container), 64)
        time.sleep(3)
        self.assertEqual(len(self.conn.ListContainers().containers), 0)

    def test_l_remove_image(self):
        self.assertEqual(len(self.conn.RemoveImage('alpine').image), 64)
        self.assertEqual(len(self.conn.ListImages().images), 0)

    def test_m_get_non_exist_image(self):
        with self.assertRaises(VarlinkError) as context:
            self.conn.GetImage('non-exist')
        self.assertTrue('io.podman.ImageNotFound' in str(context.exception))

    def test_n_get_non_exist_container(self):
        with self.assertRaises(VarlinkError) as context:
            self.conn.GetContainer('non-exist')
        self.assertTrue('io.podman.ContainerNotFound' in str(context.exception))


    @classmethod
    def tearDownClass(cls):
        # Delete all containers
        subprocess.call('podman rm -af', shell=True)
        # Delete all images
        subprocess.call('podman rmi -af', shell=True)

        cls.conn.close()
        cls._client.cleanup()


if __name__ == '__main__':
    unittest.main(verbosity=2)
