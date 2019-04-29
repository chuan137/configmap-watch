# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Use the native vendor/ dependency system
export GO15VENDOREXPERIMENT=1

# Bump this on release
VERSION ?= v0.1.0

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
BUILD_DIR ?= ./out
DOCKER_IMAGE_NAME ?= mx3d/configmap-watch
DOCKER_IMAGE_TAG ?= $(VERSION)

LDFLAGS := -s -w -extldflags '-static'

out/configmap-watch: out/configmap-watch-$(GOOS)-$(GOARCH)
	cp $(BUILD_DIR)/configmap-watch-$(GOOS)-$(GOARCH) $(BUILD_DIR)/configmap-watch

out/configmap-watch-linux-ppc64le: configmap-watch.go $(shell $(SRCFILES))
	CGO_ENABLED=0 GOARCH=ppc64le GOOS=linux go build --installsuffix cgo -ldflags="$(LDFLAGS)" -a -o $(BUILD_DIR)/configmap-watch-linux-ppc64le configmap-watch.go


out/configmap-watch-darwin-amd64: configmap-watch.go $(shell $(SRCFILES))
	CGO_ENABLED=0 GOARCH=amd64 GOOS=darwin go build --installsuffix cgo -ldflags="$(LDFLAGS)" -a -o $(BUILD_DIR)/configmap-watch-darwin-amd64 configmap-watch.go

out/configmap-watch-linux-amd64: configmap-watch.go $(shell $(SRCFILES))
	CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build --installsuffix cgo -ldflags="$(LDFLAGS)" -a -o $(BUILD_DIR)/configmap-watch-linux-amd64 configmap-watch.go

out/configmap-watch-windows-amd64.exe: configmap-watch.go $(shell $(SRCFILES))
	CGO_ENABLED=0 GOARCH=amd64 GOOS=windows go build --installsuffix cgo -ldflags="$(LDFLAGS)" -a -o $(BUILD_DIR)/configmap-watch-windows-amd64.exe configmap-watch.go

.PHONY: cross
cross: out/configmap-watch-linux-amd64 out/configmap-watch-darwin-amd64 out/configmap-watch-windows-amd64.exe

.PHONY: checksum
checksum:
	for f in out/localkube out/configmap-watch-linux-amd64 out/configmap-watch-darwin-amd64 out/configmap-watch-windows-amd64.exe ; do \
		if [ -f "$${f}" ]; then \
			openssl sha256 "$${f}" | awk '{print $$2}' > "$${f}.sha256" ; \
		fi ; \
	done


.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: docker
docker: out/configmap-watch Dockerfile
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .
