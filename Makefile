LUNA=6.2
NAME=luna-client

all: build push

dist:
	$(MAKE) LUNA=6.2
	$(MAKE) LUNA=7.2
	$(MAKE) LUNA=7.4

.PHONY: Dockerfile

Dockerfile: Dockerfile.in
	env LUNA=$(LUNA) envsubst < $< > $@

build: Dockerfile
	docker build --no-cache=true -t $(NAME):$(VERSION) .
	docker tag $(NAME):$(VERSION) docker.sunet.se/$(NAME):$(VERSION)

push:
	docker push docker.sunet.se/$(NAME):$(VERSION)
