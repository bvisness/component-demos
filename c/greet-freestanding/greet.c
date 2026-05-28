#include <stddef.h>
#include <stdint.h>

typedef struct {
  char *ptr;
  size_t len;
} string_t;

static string_t greet_ret;
static char greet_buf[4096];

[[clang::export_name("greet")]]
const string_t *greet(const char *name, size_t name_len) {
  static const char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;

  for (size_t i = 0; i < prefix_len; i++) {
    greet_buf[i] = prefix[i];
  }
  for (size_t i = 0; i < name_len; i++) {
    greet_buf[prefix_len + i] = name[i];
  }

  greet_ret = (string_t){.ptr = greet_buf, .len = prefix_len + name_len};
  return &greet_ret;
}

// ============================================================================
// C ABI helpers

static uint8_t heap[16 * 1024];
static size_t heap_top = 0;

// A simple and incomplete implementation of realloc that uses a simple bump
// allocator for demonstration purposes.
[[clang::export_name("cabi_realloc")]]
void *cabi_realloc(void *old_ptr, size_t old_size, size_t align,
                   size_t new_size) {
  size_t aligned = (heap_top + align - 1) & ~(align - 1);
  if (aligned + new_size > sizeof(heap)) {
    __builtin_trap();
  }
  heap_top = aligned + new_size;
  return heap + aligned;
}
