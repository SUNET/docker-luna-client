VER=latest
NAME=luna-xmlsec

all: build push
build:
	docker build --no-cache=true -t $(NAME) .
	docker tag -f $(NAME) docker.sunet.se/$(NAME):$(VER)
update:
	docker build -t $(NAME) .
	docker tag -f $(NAME) docker.sunet.se/$(NAME):$(VER)
push:
	docker push docker.sunet.se/$(NAME):$(VER)
