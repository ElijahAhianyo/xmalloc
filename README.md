# xmalloc
A rudimentary implementation of heap allocation(`malloc`, `calloc`, `realloc` and `free`) in aarch64 asm for educational purposes.
I wrote this primarily to experiment an `sbrk` based malloc vs an `mmap` based malloc in assmebly.
The core logic is written in aassemblt and the glue code to test this is written in c.

This currently contains an `sbrk` malloc implementation with no thread safety. `mmap` implementation (as well as concurrency) will be added in the future.


# How to run

This only works on a linux aarch64 supported machine. To run this. To test this, you should have [just](https://just.systems/man/en/packages.html) installed. 
First build by running:

> just build

This generates a binary `main` which you can run using the command

> ./main
