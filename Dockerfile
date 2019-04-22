FROM ubuntu:14.04
MAINTAINER leifj@sunet.se
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -q update
RUN apt-get -y upgrade
COPY luna-client /usr/src/luna-client
WORKDIR /usr/src/luna-client
RUN dpkg -i ckdemo_6.2.0-16_amd64.deb cklog_6.2.0-16_amd64.deb cksample_6.2.0-16_amd64.deb configurator_6.2.0-16_amd64.deb htl-client_6.2.0-16_amd64.deb libcryptoki_6.2.0-16_amd64.deb libshim_6.2.0-16_amd64.deb lunacm_6.2.0-16_amd64.deb lunacmu_6.2.0-16_amd64.deb lunadiag_6.2.0-16_amd64.deb multitoken_6.2.0-16_amd64.deb salogin_6.2.0-16_amd64.deb uhd_6.2.0-16_amd64.deb vkd_6.1.1-2_amd64.deb vtl_6.2.0-16_amd64.deb
RUN apt-get -y install opensc git-core python-dev build-essential libz-dev python-pip mercurial swig dnsutils
RUN pip install --upgrade pkcs11
#RUN pip install --upgrade hg+https://bitbucket.org/PyKCS11/pykcs11#egg=pykcs11
RUN pip install --upgrade git+git://github.com/leifj/pyeleven.git#egg=pyeleven
RUN pip install gunicorn flask
WORKDIR /
RUN rm -rf /usr/src/luna-client
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
