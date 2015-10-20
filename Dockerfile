FROM ubuntu
MAINTAINER leifj@sunet.se
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update
RUN apt-get -y install xmlsec1
COPY luna-client /usr/src/luna-client
WORKDIR /usr/src/luna-client
RUN dpkg -i ckdemo_5.4.1-3_amd64.deb cklog_5.4.1-3_amd64.deb cksample_5.4.1-3_amd64.deb configurator_5.4.1-3_amd64.deb htl-client_5.4.1-3_amd64.deb libcryptoki_5.4.1-3_amd64.deb libshim_5.4.1-3_amd64.deb lunacm_5.4.1-3_amd64.deb lunacmu_5.4.1-3_amd64.deb lunadiag_5.4.1-3_amd64.deb lunadpc_1.1.0-5_amd64.deb multitoken_5.4.1-3_amd64.deb salogin_5.4.1-3_amd64.deb uhd_5.4.1-3_amd64.deb vkd_5.4.1-3_amd64.deb vtl_5.4.1-3_amd64.deb
WORKDIR /
RUN rm -rf /usr/src/luna-client
ENV PATH /usr/safenet/lunaclient/bin:/usr/safenet/lunaclient/sbin:/usr/local/bin:/usr/bin:/bin
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
