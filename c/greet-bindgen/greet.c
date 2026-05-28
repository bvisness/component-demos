#include <stdlib.h>
#include <string.h>

#include "bindings/greet.h"

void exports_greet_greet(greet_string_t *name, greet_string_t *ret) {
  static char prefix[] = "Hello, ";
  size_t prefix_len = sizeof(prefix) - 1;
  size_t total = prefix_len + name->len;

  ret->ptr = malloc(total);
  ret->len = total;
  memcpy(ret->ptr, prefix, prefix_len);
  memcpy(ret->ptr + prefix_len, name->ptr, name->len);

  // The host will call cabi_realloc to pass us `name`, so we are responsible
  // for freeing it.
  greet_string_free(name);
}
