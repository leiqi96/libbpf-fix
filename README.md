# libbpf-fix

# fail to get  the pinned bpf map

# Enviroment

```
# uname -r
5.13.0-51-generic

# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 21.10
Release:        21.10
Codename:       impish

```



## Repetition steps



```
# make

//The first time it will get file successfully and create a pinned path
# ./libbpfgo-prog  
success:get bpf map name process_pinned_map

# ll /sys/fs/bpf/process_pinned_map

// If executed again, it will fail
# ./libbpfgo-prog  
failed to find BPF map process_pinned_map: no such file or directory
```





## Solution



If the name of pinned map are the same as the name of bpf object for the first  (BPF_OBJ_NAME_LEN - 1),  bpf map name still uses the name of bpf object.



patch file: 3rdparty/0001-libbpf-Fix-the-name-of-a-reused-map.patch

```c
---
 src/libbpf.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/src/libbpf.c b/src/libbpf.c
index 8a45a84..2cb947a 100644
--- a/src/libbpf.c
+++ b/src/libbpf.c
@@ -4232,7 +4232,7 @@ int bpf_map__set_autocreate(struct bpf_map *map, bool autocreate)
 int bpf_map__reuse_fd(struct bpf_map *map, int fd)
 {
 	struct bpf_map_info info = {};
-	__u32 len = sizeof(info);
+	__u32 len = sizeof(info), name_len;
 	int new_fd, err;
 	char *new_name;
 
@@ -4242,7 +4242,12 @@ int bpf_map__reuse_fd(struct bpf_map *map, int fd)
 	if (err)
 		return libbpf_err(err);
 
-	new_name = strdup(info.name);
+	name_len = strlen(info.name);
+	if (name_len == BPF_OBJ_NAME_LEN - 1 && strncmp(map->name, info.name, name_len) == 0)
+		new_name = strdup(map->name);
+	else
+		new_name = strdup(info.name);
+
 	if (!new_name)
 		return libbpf_err(-errno);
 
-- 
```



Apply the patch above

```
#  make patch
#  make

// the pinned map path still exists
#  ll /sys/fs/bpf/process_pinned_map  

// it can get map successfully
#  ./libbpfgo-prog
success:get bpf map name process_pinned_map
```



```
// You can go back to the last commit with make uppatch
# make unpatch
```

