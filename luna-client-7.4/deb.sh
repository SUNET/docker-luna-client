#!/bin/sh

wget http://mirrors.edge.kernel.org/ubuntu/pool/main/g/gcc-10/gcc-10-base_10-20200411-0ubuntu1_amd64.deb
wget http://mirrors.xmission.com/ubuntu/pool/main/g/gcc-10/libgcc-s1_10-20200411-0ubuntu1_amd64.deb
dpkg -i gcc-10-base_10-20200411-0ubuntu1_amd64.deb libgcc-s1_10-20200411-0ubuntu1_amd64.deb

apt-get install -y libcap2 libgcc-s1 && dpkg -i ckdemo_7.4.0-227_amd64.deb cklog_7.4.0-227_amd64.deb cksample_7.4.0-227_amd64.deb configurator_7.4.0-227_amd64.deb libcryptoki_7.4.0-227_amd64.deb libshim_7.4.0-227_amd64.deb lunacm_7.4.0-227_amd64.deb lunacmu_7.4.0-227_amd64.deb lunadiag_7.4.0-227_amd64.deb multitoken_7.4.0-227_amd64.deb salogin_7.4.0-227_amd64.deb uhd_7.2.0-221_amd64.deb vtl_7.4.0-227_amd64.deb
