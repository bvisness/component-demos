#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *ptr;
  size_t len;
} string_t;

static string_t greet_ret;

[[clang::export_name("greet")]]
string_t *greet(char *name, size_t name_len) {
  static char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;
  size_t total = prefix_len + name_len;

  char *buf = malloc(total);
  memcpy(buf, prefix, prefix_len);
  memcpy(buf + prefix_len, name, name_len);

  // The host will call cabi_realloc to pass us `name`, so we are responsible
  // for freeing it.
  free(name);

  greet_ret = (string_t){.ptr = buf, .len = total};
  return &greet_ret;
}

// ============================================================================
// C ABI helpers

[[clang::export_name("cabi_realloc")]]
void *cabi_realloc(void *old_ptr, size_t old_size, size_t align,
                   size_t new_size) {
  return realloc(old_ptr, new_size);
}

[[clang::export_name("cabi_post_greet")]]
void cabi_post_greet(const string_t *ret) {
  free(ret->ptr);
}
