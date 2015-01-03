.PHONY: default assets client-assets server-assets server client all clean contributors

GOBINDATA ?= $(GOPATH)/bin/go-bindata

default: all

assets: client-assets server-assets

client-assets:
	$(GOBINDATA) -nomemcopy -pkg=assets \
		-o=client/assets/assets.go \
		assets/client/...

server-assets:
	$(GOBINDATA) -nomemcopy -pkg=assets \
		-o=server/assets/assets.go \
		assets/server/...

ngrokd:
	go build server/daemon/ngrokd.go

ngrok:
	go build

all: ngrok ngrokd

clean-ngrokd:
	go clean -i -x server/daemon/ngrokd.go
	rm -f ngrokd

clean-ngrok:
	go clean -i -x

clean: clean-ngrokd clean-ngrok

contributors:
	echo "Contributors to ngrok, both large and small:\n" > CONTRIBUTORS
	git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' | cut -d '<' -f1 >> CONTRIBUTORS
