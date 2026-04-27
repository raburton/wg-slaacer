OUTPUT := build
SOURCE := src
CLANG := clang
CC := gcc
BPFTOOL := bpftool

BPF_SRC := $(SOURCE)/provisioner.bpf.c
USER_SRC := $(SOURCE)/provisioner.c

# Installation
PREFIX ?= /usr/local
SBINDIR ?= $(PREFIX)/sbin
INSTALL_NAME ?= wg-slaacer
SYSTEMD_DIR ?= /etc/systemd/system

# Path to generated artifacts
VMLINUX_H := $(OUTPUT)/vmlinux.h
BPF_OBJ := $(OUTPUT)/provisioner.bpf.o
SKEL := $(OUTPUT)/provisioner.skel.h
USER_OBJ := $(OUTPUT)/provisioner.o
BINARY := $(OUTPUT)/wg-slaacer

# Include paths: current dir for provisioner.h, build dir for provisioner.skel.h
CFLAGS := -g -O2 -Wall -I. -I$(OUTPUT)
LIBS := -lbpf -lpthread -lmnl
DOS_PROTECTION ?= 1

BPF_CFLAGS := -g -O2 -target bpf -D__TARGET_ARCH_x86 -I. -I$(OUTPUT)
ifeq ($(DOS_PROTECTION),1)
BPF_CFLAGS += -DENABLE_DOS_PROTECTION
CFLAGS += -DENABLE_DOS_PROTECTION
endif

.PHONY: all clean install uninstall

all: $(BINARY)

$(OUTPUT):
	mkdir -p $(OUTPUT)

$(VMLINUX_H): | $(OUTPUT)
		$(BPFTOOL) btf dump file /sys/kernel/btf/vmlinux format c > $(VMLINUX_H)

$(BPF_OBJ): $(BPF_SRC) $(VMLINUX_H) | $(OUTPUT)
	$(CLANG) $(BPF_CFLAGS) -c $< -o $@

$(SKEL): $(BPF_OBJ) | $(OUTPUT)
	$(BPFTOOL) gen skeleton $< > $@

$(USER_OBJ): $(USER_SRC) $(SKEL) | $(OUTPUT)
	$(CC) $(CFLAGS) -c $< -o $@

$(BINARY): $(USER_OBJ)
	$(CC) $(CFLAGS) $^ $(LIBS) -o $@

clean:
	rm -rf $(OUTPUT)

install: all
	mkdir -p $(SBINDIR)
	install -m 0755 $(BINARY) $(SBINDIR)/$(INSTALL_NAME)
	# Install systemd service and reload daemon
	install -m 0644 $(SOURCE)/wg-slaacer.service $(SYSTEMD_DIR)/$(INSTALL_NAME).service || true;
	if command -v systemctl >/dev/null 2>&1; then systemctl daemon-reload || true; fi;

uninstall:
	rm -f $(SBINDIR)/$(INSTALL_NAME)
	rm -f $(SYSTEMD_DIR)/$(INSTALL_NAME).service || true
	if command -v systemctl >/dev/null 2>&1; then systemctl daemon-reload || true; fi
