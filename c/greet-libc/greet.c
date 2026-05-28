#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// -----------------------------------------------------------------------------
// cabi_realloc
// -----------------------------------------------------------------------------
// Called by the host to allocate space in our linear memory for owned input
// parameters (and, if it ever needed to, for return areas).
//
// libc's realloc returns max-aligned pointers (>= alignof(max_align_t)), which
// covers every WIT primitive's alignment requirement, so we can ignore `align`.
// `old_size` is unused too -- realloc tracks allocation sizes internally.

void *cabi_realloc(void *old_ptr, size_t old_size, size_t align, size_t new_size) {
  (void)old_size;
  (void)align;
  return realloc(old_ptr, new_size);
}

// -----------------------------------------------------------------------------
// greet(name: string) -> string
// -----------------------------------------------------------------------------
// Core signature: (i32 name_ptr, i32 name_len) -> i32 ret_record_ptr
// where ret_record_ptr points to a (ptr, len) record describing the returned
// string in our linear memory.

typedef struct {
  uint32_t ptr;
  uint32_t len;
} string_t;

static string_t greet_ret;

const string_t *greet(const char *name, size_t name_len) {
  static const char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;
  size_t total = prefix_len + name_len;

  char *buf = malloc(total);
  memcpy(buf, prefix, prefix_len);
  memcpy(buf + prefix_len, name, name_len);

  // Owned parameter: the host transferred ownership of `name` to us via the
  // canonical ABI, so we free it once we've consumed the bytes.
  free((void *)name);

  greet_ret.ptr = (uint32_t)(uintptr_t)buf;
  greet_ret.len = (uint32_t)total;
  return &greet_ret;
}

// -----------------------------------------------------------------------------
// cabi_post_greet
// -----------------------------------------------------------------------------
// Optional cleanup hook. The host calls this after it has finished reading the
// lifted return value, passing the same record pointer `greet` returned. We
// free the malloc'd string buffer here; the static record itself stays put.

void cabi_post_greet(const string_t *ret) {
  free((void *)(uintptr_t)ret->ptr);
}
