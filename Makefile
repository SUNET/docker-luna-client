LUNA=6.2
PYELEVENSRC=git+git://github.com/IdentityPython/pyeleven.git\#egg=pyeleven
PYELEVEN=dev
NAME=luna-client
VERSION=$(LUNA)-$(PYELEVEN)

all: build push

dist:
	$(MAKE) LUNA=6.2 PYELEVENSRC=git+git://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="dev"
	$(MAKE) LUNA=7.2 PYELEVENSRC=git+git://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="dev"
	$(MAKE) LUNA=7.4 PYELEVENSRC=git+git://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="dev"

.PHONY: Dockerfile

Dockerfile: Dockerfile.in
	env LUNA=$(LUNA) PYELEVENSRC=$(PYELEVENSRC) PYELEVEN=$(PYELEVEN) envsubst < $< > $@

build: Dockerfile
	docker build --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)

push:
	docker push docker.sunet.se/$(NAME):$(VERSION)
