#include <stdlib.h>
#include <string.h>

#include "bindings/greet.h"

void exports_greet_greet(greet_string_t *name, greet_string_t *ret) {
  static const char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;
  size_t total = prefix_len + name->len;

  ret->ptr = malloc(total);
  ret->len = total;
  memcpy(ret->ptr,              prefix,    prefix_len);
  memcpy(ret->ptr + prefix_len, name->ptr, name->len);

  // The host transferred ownership of `name` to us. The generated wrapper
  // doesn't free it; we do.
  greet_string_free(name);
}
