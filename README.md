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
# ./libbpfc-prog  

success get fd 4

# ll /sys/fs/bpf/process_pinned_map

// If executed again, it will fail
# ./libbpfc-prog  
error: map fd is -22
```





## Solution



If the name of pinned map are the same as the name of bpf object for the first  (BPF_OBJ_NAME_LEN - 1),  bpf map name still uses the name of bpf object.



path file: 3rdparty/0001-libbpf-fix-inconsistencies-between-kernel-map-name-a.patch

```c
---
 src/libbpf.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/src/libbpf.c b/src/libbpf.c
index 8a45a84..7eb9b4a 100644
--- a/src/libbpf.c
+++ b/src/libbpf.c
@@ -4233,6 +4233,7 @@ int bpf_map__reuse_fd(struct bpf_map *map, int fd)
 {
 	struct bpf_map_info info = {};
 	__u32 len = sizeof(info);
+	__u32 name_len;
 	int new_fd, err;
 	char *new_name;
 
@@ -4242,7 +4243,12 @@ int bpf_map__reuse_fd(struct bpf_map *map, int fd)
 	if (err)
 		return libbpf_err(err);
 
-	new_name = strdup(info.name);
+	name_len = strlen(info.name);
+	if ((BPF_OBJ_NAME_LEN - 1) == name_len && !strncmp(map->name, info.name, name_len))
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
#  make clean
#  make

// the pinned map path still exists
#  ll /sys/fs/bpf/process_pinned_map  

// it can get map successfully
#  ./libbpfc-prog
success get fd 5
```



```
// You can go back to the last commit with command
# make unpatch
```

