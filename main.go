package main

//import "C"

import (
	"fmt"
	"os"

	bpf "github.com/aquasecurity/libbpfgo"
)

func getSupposedPinPath(m *bpf.BPFMap) string {
	return "/sys/fs/bpf/" + m.GetName()
}

type Value struct {
	x int
}

func main() {
	bpfModule, err := bpf.NewModuleFromFile("simple.bpf.o")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(-1)
	}
	defer bpfModule.Close()

	bpfModule.BPFLoadObject()

	pinnedMap, err := bpfModule.GetMap("process_pinned_map")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(-1)
	} else {
		fmt.Printf("success:get bpf map name %s\n", pinnedMap.Name())
	}

}
