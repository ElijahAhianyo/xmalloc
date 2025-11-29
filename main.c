#include <stdio.h>
#include <stddef.h>  
#include <stdint.h>   

extern void *malloc(size_t size);
extern void *calloc(size_t nmemb, size_t size);
extern void *realloc(void *ptr, size_t size);
extern void free(void *ptr);

int main(void) {
    
    int *p = (int *)malloc(sizeof(int));
    if (!p) {
        fprintf(stderr, "malloc failed\n");
        return 1;
    }
    *p = 42;
    printf("malloc -> %p value=%d\n", (void*)p, *p);

    // calloc: allocate array of 5 ints
    int *arr = (int *)calloc(5, sizeof(int));
    if (!arr) {
        fprintf(stderr, "calloc failed\n");
        free(p);
        return 1;
    }
    printf("calloc -> %p values:", (void*)arr);
    for (int i = 0; i < 5; ++i) printf(" %d", arr[i]);
    printf("\n");

    // realloc: grow array to 10 ints
    int *arr2 = (int *)realloc(arr, 10 * sizeof(int));
    if (!arr2) {
        fprintf(stderr, "realloc failed\n");
        free(p);
        free(arr);
        return 1;
    }
    arr2[5] = 99;
    printf("realloc -> %p arr2[5]=%d\n", (void*)arr2, arr2[5]);

    free(p);
    free(arr2);

    return 0;
}
