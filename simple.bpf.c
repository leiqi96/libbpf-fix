//+build ignore
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>

struct value {
	int x;
};


struct {
	__uint(type, BPF_MAP_TYPE_HASH);
	__type(key, u32);
	__type(value, struct value);
	__uint(max_entries, 1<<10);	
	__uint(pinning, LIBBPF_PIN_BY_NAME);
} process_pinned_map SEC(".maps");

char LICENSE[] SEC("license") = "GPL";
