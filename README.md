# gdb script

## Introduction
This is a gdb script which is used to debug the most common data structure on both Android and Linux.

## Run
- start your gdb
  ```
  $ gdb
  (gdb) file /path/to/binary
  (gdb) set args arg1 arg2
  (gdb) b /path/to/source file
  (gdb) run
  ```

- source your .gdbinit file
  ```
  (gdb) source /path/to/.gdbinit
  ```

- start debugging your code
  ```
  (gdb) pstring 0x67ece0
  "conv1"
  ```
