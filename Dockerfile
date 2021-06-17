FROM ubuntu:18.04
MAINTAINER leifj@sunet.se
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -q update
RUN apt-get -y upgrade
COPY luna-client-6.2 /usr/src/luna-client
WORKDIR /usr/src/luna-client
RUN ./deb.sh
RUN apt-get -y install opensc git-core python-dev build-essential libz-dev python-pip mercurial swig dnsutils
RUN pip install --upgrade pykcs11 
RUN pip install --upgrade git+git://github.com/IdentityPython/pyeleven.git#egg=pyeleven
RUN pip install gunicorn flask
WORKDIR /
RUN rm -rf /usr/src/luna-client
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
