LUNA=7.4
PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven
PYELEVEN=0.0.2
NAME=luna-client
VERSION=$(LUNA)-$(PYELEVEN)

all: build push

dist:
	$(MAKE) LUNA=7.4

.PHONY: Dockerfile

Dockerfile: Dockerfile.in
	env LUNA=$(LUNA) PYELEVENSRC=$(PYELEVENSRC) PYELEVEN=$(PYELEVEN) envsubst < $< > $@

build: Dockerfile
	docker build --platform linux/amd64 --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)

push:
	echo docker push docker.sunet.se/$(NAME):$(VERSION)
