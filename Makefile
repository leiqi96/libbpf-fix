
all: pre-build bpf_target skel c_target

LIBBPF_CFLAGS = "-fPIC"
LIBBPF_LDLAGS =
LIBBPF_SRC = ./3rdparty/libbpf/src

LIBBPF_UAPI := $(abspath $(LIBBPF)/include/uapi)
LIBBPF_OBJ := $(abspath $(BUILDLIB)/libbpf/libbpf.a)

BUILD := $(abspath ./build/)
DIST_DIR := $(abspath ./build/dist/)
DIST_BINDIR := $(abspath ./build/dist/bin)
DIST_LIBDIR := $(abspath ./build/dist/libs)
LIB_ELF ?= libelf
CMD_PKGCONFIG ?= pkg-config
CMD_GIT ?= git
define pkg_config
	$(CMD_PKGCONFIG) --libs $(1)
endef


CUSTOM_CGO_CFLAGS = "-I$(abspath $(DIST_LIBDIR)/libbpf)"
CUSTOM_CGO_LDFLAGS = "$(shell $(call pkg_config, $(LIB_ELF))) $(abspath $(DIST_LIBDIR)/libbpf/libbpf.a)"



.PHONY: pre-build
pre-build:
	$(info Build started)
	$(info MKDIR build directories)

	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_BINDIR)
	@mkdir -p $(DIST_LIBDIR)




$(DIST_LIBDIR)/libbpf/libbpf.a: \
	$(LIBBPF_SRC) \

#
	CC="clang" \
		CFLAGS="$(LIBBPF_CFLAGS)" \
		LD_FLAGS="$(LIBBPF_LDFLAGS)" \
		$(MAKE) \
		-C $(LIBBPF_SRC) \
		BUILD_STATIC_ONLY=1 \
		DESTDIR=$(DIST_LIBDIR)/libbpf \
		OBJDIR=$(DIST_LIBDIR)/libbpf/obj \
		INCLUDEDIR= LIBDIR= UAPIDIR= prefix= libdir= \
		install install_uapi_headers

$(LIBBPF_SRC): 
#
ifeq ($(wildcard $@), )
	@$(CMD_GIT) submodule update --init --recursive
endif
	

patch:
	cd ./3rdparty/libbpf/ && git am --signoff ../*.patch

unpatch:
	cd ./3rdparty/libbpf/ && git reset HEAD~1 --hard

# vmlinux.h:
# 	bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h



bpf_target: $(DIST_LIBDIR)/libbpf/libbpf.a simple.bpf.c
	clang -g  -target bpf -D__TARGET_ARCH_amd64 -I$(DIST_LIBDIR)/libbpf -c simple.bpf.c -o simple.bpf.o

skel:
	bpftool gen skeleton simple.bpf.o > simple.bpf.skel.h


c_target: simple.bpf.o main.c
	clang -v -g  -I$(DIST_LIBDIR)/libbpf -I/usr/include -lelf -lz -o libbpfc-prog main.c $(DIST_LIBDIR)/libbpf/libbpf.a
	#clang -v -o -g libbpfc-prog main.c -L$(DIST_LIBDIR)/libbpf -lbpf  -lelf
	#clang -v -g  -I$(DIST_LIBDIR)/libbpf -I/usr/include -lelf -lz -L$(DIST_LIBDIR)/libbpf -L/usr/lib64/ -static -lbpf  -o libbpfc-prog main.c $(DIST_LIBDIR)/libbpf/libbpf.a

clean:
	rm -r $(BUILD)/*
	rm simple.bpf.skel.h simple.bpf.o libbpfc-prog 

