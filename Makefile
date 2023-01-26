CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
# handle the case where podman is present but is (defaulting) to remote and is
# not not functioning correctly. Example: mac platform but no 'podman machine'
# vms are ready
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman --version >/dev/null 2>&1 && echo podman)
ifneq ($(CONTAINER_CMD),)
$(warning podman detected but 'podman version' failed. \
	this may mean your podman is set up for remote use, but is not working)
endif
endif

BUILD_CMD:=$(CONTAINER_CMD) build $(BUILD_OPTS)
PUSH_CMD:=$(CONTAINER_CMD) push $(PUSH_OPTS)
SHELLCHECK:=shellcheck

SERVER_DIR:=images/server
AD_SERVER_DIR:=images/ad-server
CLIENT_DIR:=images/client
TOOLBOX_DIR:=images/toolbox
SERVER_SRC_FILE:=$(SERVER_DIR)/Containerfile
SERVER_SOURCES:=\
	$(SERVER_DIR)/smb.conf
AD_SERVER_SRC_FILE:=$(AD_SERVER_DIR)/Containerfile
AD_SERVER_SOURCES:=
CLIENT_SRC_FILE:=$(CLIENT_DIR)/Containerfile
TOOLBOX_SRC_FILE:=$(TOOLBOX_DIR)/Containerfile

TAG?=latest
SERVER_NAME:=samba-container:$(TAG)
AD_SERVER_NAME:=samba-ad-container:$(TAG)
CLIENT_NAME:=samba-client-container:$(TAG)
TOOLBOX_NAME:=samba-toolbox-container:$(TAG)

SERVER_REPO_NAME:=registry.opensuse.org/opensuse/samba-server:$(TAG)
AD_SERVER_REPO_NAME:=registry.opensuse.org/opensuse/samba-ad-server:$(TAG)
CLIENT_REPO_NAME:=registry.opensuse.org/opensuse/samba-client:$(TAG)
TOOLBOX_REPO_NAME:=registry.opensuse.org/opensuse/samba-toolbox:$(TAG)

BUILDFILE_SERVER:=.build.server
BUILDFILE_AD_SERVER:=.build.ad-server
BUILDFILE_CLIENT:=.build.client
BUILDFILE_TOOLBOX:=.build.toolbox

build: build-server build-ad-server build-client \
	build-toolbox
.PHONY: build

build-server: $(BUILDFILE_SERVER)
.PHONY: build-server
$(BUILDFILE_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(BUILD_CMD) \
		--tag $(SERVER_NAME) --tag $(SERVER_REPO_NAME) \
		-f $(SERVER_SRC_FILE) $(SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(SERVER_NAME) > $(BUILDFILE_SERVER)

build-ad-server: $(BUILDFILE_AD_SERVER)
.PHONY: build-ad-server
$(BUILDFILE_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(BUILD_CMD) --tag $(AD_SERVER_NAME) --tag $(AD_SERVER_REPO_NAME) -f $(AD_SERVER_SRC_FILE) $(AD_SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(AD_SERVER_NAME) > $(BUILDFILE_AD_SERVER)

build-client: $(BUILDFILE_CLIENT)
.PHONY: build-client
$(BUILDFILE_CLIENT): Makefile $(CLIENT_SRC_FILE)
	$(BUILD_CMD) --tag $(CLIENT_NAME) --tag $(CLIENT_REPO_NAME) -f $(CLIENT_SRC_FILE) $(CLIENT_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(CLIENT_NAME) > $(BUILDFILE_CLIENT)

test: test-server
.PHONY: test

test-server: build-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-server


build-toolbox: $(BUILDFILE_TOOLBOX)
.PHONY: build-toolbox
$(BUILDFILE_TOOLBOX): Makefile $(TOOLBOX_SRC_FILE)
	$(BUILD_CMD) --tag $(TOOLBOX_NAME) --tag $(TOOLBOX_REPO_NAME) -f $(TOOLBOX_SRC_FILE) $(TOOLBOX_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(TOOLBOX_NAME) > $(BUILDFILE_TOOLBOX)


check: check-shell-scripts
.PHONY: check

# rule requires shellcheck and find to run
check-shell-scripts:
	$(SHELLCHECK) -P tests/ -eSC2181 -fgcc $$(find  -name '*.sh')
.PHONY: check-shell-scripts

clean:
	$(RM) $(BUILDFILE_SERVER) $(BUILDFILE_AD_SERVER) $(BUILDFILE_CLIENT) $(BUILDFILE_TOOLBOX)
.PHONY: clean
