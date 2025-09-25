APP=tfrun
VERSION=0.1.0
COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)

.PHONY: build test dist deb clean help

help:
	@echo "Available targets:"
	@echo "  build      - Build the binary to bin/$(APP)"
	@echo "  install    - Build and install to /opt/homebrew/bin"
	@echo "  test       - Run all tests"
	@echo "  dist       - Build distribution binaries for multiple platforms"
	@echo "  deb        - Build Debian package"
	@echo "  clean      - Clean build artifacts"
	@echo "  redeploy   - Clean and rebuild"
	@echo "  help       - Show this help message"

build:
	mkdir -p bin
	go build -ldflags "-X tfrun/cmd/tfrun.version=$(VERSION) -X tfrun/cmd/tfrun.commit=$(COMMIT) -X tfrun/cmd/tfrun.date=$(DATE)" -o bin/$(APP) .

install: build
	cp bin/$(APP) /opt/homebrew/bin/$(APP) 2>/dev/null || echo "Could not install to /opt/homebrew/bin, run 'sudo make install' or add bin/ to PATH"

test:
	go test ./...

dist: clean
	mkdir -p dist
	GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -X tfrun/cmd/tfrun.version=$(VERSION) -X tfrun/cmd/tfrun.commit=$(COMMIT) -X tfrun/cmd/tfrun.date=$(DATE)" -o dist/$(APP)-linux-amd64 .
	GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w -X tfrun/cmd/tfrun.version=$(VERSION) -X tfrun/cmd/tfrun.commit=$(COMMIT) -X tfrun/cmd/tfrun.date=$(DATE)" -o dist/$(APP)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build -ldflags "-s -w -X tfrun/cmd/tfrun.version=$(VERSION) -X tfrun/cmd/tfrun.commit=$(COMMIT) -X tfrun/cmd/tfrun.date=$(DATE)" -o dist/$(APP)-darwin-arm64 .
	GOOS=linux GOARCH=arm64 go build -ldflags "-s -w -X tfrun/cmd/tfrun.version=$(VERSION) -X tfrun/cmd/tfrun.commit=$(COMMIT) -X tfrun/cmd/tfrun.date=$(DATE)" -o dist/$(APP)-linux-arm64 .
	cd dist && tar -czf $(APP)_$(VERSION)_linux_amd64.tar.gz $(APP)-linux-amd64 && tar -czf $(APP)_$(VERSION)_linux_arm64.tar.gz $(APP)-linux-arm64 && tar -czf $(APP)_$(VERSION)_darwin_amd64.tar.gz $(APP)-darwin-amd64 && tar -czf $(APP)_$(VERSION)_darwin_arm64.tar.gz $(APP)-darwin-arm64

deb: build
	mkdir -p dist/deb/usr/local/bin dist/deb/DEBIAN
	cp bin/$(APP) dist/deb/usr/local/bin/tf-run
	echo "Package: tf-run" > dist/deb/DEBIAN/control
	echo "Version: $(VERSION)" >> dist/deb/DEBIAN/control
	echo "Section: utils" >> dist/deb/DEBIAN/control
	echo "Priority: optional" >> dist/deb/DEBIAN/control
	echo "Architecture: amd64" >> dist/deb/DEBIAN/control
	echo "Maintainer: You <garajamohan@gmail.com>" >> dist/deb/DEBIAN/control
	echo "Description: Git-aware Terraform runner" >> dist/deb/DEBIAN/control
	dpkg-deb --build dist/deb dist/tf-run_$(VERSION)_amd64.deb

clean:
	rm -rf bin dist

redeploy: clean build