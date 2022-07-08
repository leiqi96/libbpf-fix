#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/resource.h>
#include <bpf/libbpf.h>

#include "simple.bpf.skel.h"
int main(int argc, char *argv[]) {
    struct simple_bpf *skel;
    skel = simple_bpf__open_and_load();

	int fd = bpf_object__find_map_fd_by_name(skel->obj, "process_pinned_map");

    if ( fd < 0 ) {
        printf("error: map fd is %d\n", fd);
    } else {
        printf("success get fd %d\n", fd);
    }

}