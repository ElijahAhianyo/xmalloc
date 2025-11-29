
build:
    gcc -no-pie -g -Wall -o main main.c data.s sbrk.s utils.s malloc.s calloc.s realloc.s free.s
    @echo "sucessfully built main"

run: build
    ./main