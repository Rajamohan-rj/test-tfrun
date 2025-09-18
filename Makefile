APP=tfrun
VERSION=0.1.0

.PHONY: build test dist deb clean

build:
	go build -ldflags "-X main.version=$(VERSION) -X main.commit=$$(git rev-parse --short HEAD 2>/dev/null || echo none) -X main.date=$$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o bin/$(APP) ./cmd/tfrun
	mv bin/$(APP) /opt/homebrew/bin/$(APP) || true

test:
	go test ./...

dist: clean
	GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -X main.version=$(VERSION)" -o dist/$(APP)-linux-amd64 ./cmd/tfrun
	GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w -X main.version=$(VERSION)" -o dist/$(APP)-darwin-amd64 ./cmd/tfrun
	GOOS=darwin GOARCH=arm64 go build -ldflags "-s -w -X main.version=$(VERSION)" -o dist/$(APP)-darwin-arm64 ./cmd/tfrun
	GOOS=linux GOARCH=arm64 go build -ldflags "-s -w -X main.version=$(VERSION)" -o dist/$(APP)-linux-arm64 ./cmd/tfrun
	cd dist && tar -czf $(APP)_0.1.0_linux_amd64.tar.gz $(APP)-linux-amd64 && tar -czf $(APP)_0.1.0_linux_arm64.tar.gz $(APP)-linux-arm64 && tar -czf $(APP)_0.1.0_darwin_amd64.tar.gz $(APP)-darwin-amd64 && tar -czf $(APP)_0.1.0_darwin_arm64.tar.gz $(APP)-darwin-arm64

deb: build
	mkdir -p dist/deb/usr/local/bin dist/deb/DEBIAN
	cp bin/$(APP) dist/deb/usr/local/bin/tf-run
	echo "Package: tf-run" > dist/deb/DEBIAN/control
	echo "Version: 0.1.0" >> dist/deb/DEBIAN/control
	echo "Section: utils" >> dist/deb/DEBIAN/control
	echo "Priority: optional" >> dist/deb/DEBIAN/control
	echo "Architecture: amd64" >> dist/deb/DEBIAN/control
	echo "Maintainer: You <you@example.com>" >> dist/deb/DEBIAN/control
	echo "Description: Git-aware Terraform runner" >> dist/deb/DEBIAN/control
	dpkg-deb --build dist/deb dist/tf-run_0.1.0_amd64.deb

clean:
	rm -rf bin dist

redeploy: clean build