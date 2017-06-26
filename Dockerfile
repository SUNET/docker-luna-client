FROM docker.sunet.se/eduid/pythonenv

MAINTAINER eduid-dev <eduid-dev@SEGATE.SUNET.SE>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
      opensc \
      libz-dev \
      mercurial \
      dnsutils \
      swig \
      softhsm2 \
    && apt-get clean

RUN rm -rf /var/lib/apt/lists/*

RUN /opt/eduid/bin/pip install --upgrade hg+https://bitbucket.org/PyKCS11/pykcs11#egg=pykcs11
RUN /opt/eduid/bin/pip install --upgrade git+git://github.com/leifj/pyeleven.git#egg=pyeleven
RUN /opt/eduid/bin/pip install gunicorn flask

WORKDIR /

COPY start.sh /start.sh
RUN chmod 775 /start.sh

CMD ["bash", "/start.sh"]
