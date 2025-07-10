LUNA=10.9.0
TAR=610-000397-015_SW_Linux_Luna_Client_V10.9.0_RevB.tar
URL=https://sunet.drive.sunet.se/s/4z96YiBA2c3oFo3/download
SHA=8f5644e0aced01ac5718db41321d0fb6c21c5f9c80dbeda815b39cb735139e2f
PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven
PYELEVEN=0.0.2
NAME=luna-client
VERSION=$(LUNA)-$(PYELEVEN)

all: build push

dist:
	$(MAKE) LUNA=7.4
	$(MAKE) LUNA=10.9.0 TAR=610-000397-015_SW_Linux_Luna_Client_V10.9.0_RevB.tar URL=https://sunet.drive.sunet.se/s/4z96YiBA2c3oFo3/download SHA=8f5644e0aced01ac5718db41321d0fb6c21c5f9c80dbeda815b39cb735139e2f

.PHONY: Dockerfile

Dockerfile: Dockerfile.in
	env LUNA=$(LUNA) PYELEVENSRC=$(PYELEVENSRC) PYELEVEN=$(PYELEVEN) envsubst < $< > $@

build: Dockerfile
	docker build --platform linux/amd64 --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)

push:
	docker push docker.sunet.se/$(NAME):$(VERSION)
