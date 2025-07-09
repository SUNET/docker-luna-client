LUNA=6.2
PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven
PYELEVEN=0.0.1
NAME=luna-client
VERSION=$(LUNA)-$(PYELEVEN)

all: build push

dist:
	$(MAKE) LUNA=6.2 PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="$(PYELEVEN)"
	$(MAKE) LUNA=7.2 PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="$(PYELEVEN)"
	$(MAKE) LUNA=7.4 PYELEVENSRC=git+https://github.com/IdentityPython/pyeleven.git\#egg=pyeleven PYELEVEN="$(PYELEVEN)"

.PHONY: Dockerfile

Dockerfile: Dockerfile.in
	env LUNA=$(LUNA) PYELEVENSRC=$(PYELEVENSRC) PYELEVEN=$(PYELEVEN) envsubst < $< > $@

build: Dockerfile
	docker build --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)

push:
	docker push docker.sunet.se/$(NAME):$(VERSION)
