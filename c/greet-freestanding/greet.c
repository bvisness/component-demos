#include <stddef.h>
#include <stdint.h>

// -----------------------------------------------------------------------------
// cabi_realloc
// -----------------------------------------------------------------------------
// Required export. The host calls this to allocate space in our linear memory
// for owned input parameters before lowering them in (e.g. the `name` string).
//
// Canonical ABI signature:
//   cabi_realloc(old_ptr, old_size, align, new_size) -> new_ptr
//
// We only handle the fresh-allocation case (old_ptr == NULL), which covers
// everything the host needs for lowering parameters into our memory.

static uint8_t heap[16 * 1024];
static size_t  heap_top = 0;

void *cabi_realloc(void *old_ptr, size_t old_size, size_t align, size_t new_size) {
  (void)old_ptr;
  (void)old_size;
  size_t aligned = (heap_top + align - 1) & ~(align - 1);
  if (aligned + new_size > sizeof(heap)) __builtin_trap();
  heap_top = aligned + new_size;
  return heap + aligned;
}

// -----------------------------------------------------------------------------
// greet(name: string) -> string
// -----------------------------------------------------------------------------
// Canonical ABI lowering for this export:
//   param `name: string`  -> two i32s: (ptr, len) into our linear memory
//   return `string`       -> one i32: pointer to a (ptr, len) record, also
//                            in our linear memory
// So the core function signature is: (i32, i32) -> i32.

typedef struct {
  uint32_t ptr;
  uint32_t len;
} string_t;

static string_t greet_ret;
static char     greet_buf[4096];

const string_t *greet(const char *name, size_t name_len) {
  static const char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;

  for (size_t i = 0; i < prefix_len; i++) greet_buf[i]              = prefix[i];
  for (size_t i = 0; i < name_len;   i++) greet_buf[prefix_len + i] = name[i];

  greet_ret.ptr = (uint32_t)(uintptr_t)greet_buf;
  greet_ret.len = (uint32_t)(prefix_len + name_len);
  return &greet_ret;
}
