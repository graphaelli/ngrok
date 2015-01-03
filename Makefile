.PHONY: default assets client-assets server-assets server client all clean contributors clean-local-dev local-dev-client local-dev-server local-dev-asssets

LOCAL_DEV_NGROK_DOMAIN ?= ngrok.test

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
	go build -tags=release server/daemon/ngrokd.go

ngrok:
	go build -tags=release

all: ngrok ngrokd

clean-ngrokd:
	go clean -i -x server/daemon/ngrokd.go
	rm -f ngrokd

clean-ngrok:
	go clean -i -x

clean: clean-ngrokd clean-ngrok

rootCA.key:
	openssl genrsa -out rootCA.key 2048

rootCA.pem: rootCA.key
	openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$(LOCAL_DEV_NGROK_DOMAIN)" -days 5000 -out rootCA.pem

device.key:
	openssl genrsa -out device.key 2048

device.csr: device.key
	openssl req -new -key device.key -subj "/CN=${LOCAL_DEV_NGROK_DOMAIN}" -out device.csr

device.crt: device.csr rootCA.pem
	openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000

local-dev-assets: rootCA.pem
	cp rootCA.pem assets/client/tls/ngrokroot.crt

local-dev: device.crt local-dev-assets client-assets ngrok ngrokd
	@echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	@echo update /etc/hosts with entries for tunnels for $(LOCAL_DEV_NGROK_DOMAIN)
	@echo start client with: ./ngrok -config=local-dev.yml start debug
	@echo start server with: ./ngrokd -tlsKey=device.key -tlsCrt=device.crt -domain=$(LOCAL_DEV_NGROK_DOMAIN) -httpAddr=":8000" -httpsAddr=":8001"
	@echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local-dev-client: local-dev ngrok
	./ngrok -config=local-dev.yml start debug

local-dev-server: local-dev ngrokd
	./ngrokd -tlsKey=device.key -tlsCrt=device.crt -domain=$(LOCAL_DEV_NGROK_DOMAIN) -httpAddr=":8000" -httpsAddr=":8001"

clean-local-dev: clean
	rm -f rootCA.* device.*
	git checkout -- assets/client/ client/assets

contributors:
	echo "Contributors to ngrok, both large and small:\n" > CONTRIBUTORS
	git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' | cut -d '<' -f1 >> CONTRIBUTORS
