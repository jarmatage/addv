#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#define DEPTH 16

static uint8_t fifo[DEPTH];
static int head = 0;  // write index
static int tail = 0;  // read index
static int count = 0;

// Push value into FIFO
void fifo_push(uint8_t data) {
    if (count < DEPTH) {
        fifo[head] = data;
        head = (head + 1) % DEPTH;
        count++;
    } else {
        printf("[C FIFO] push attempted when full!\n");
    }
}

// Pop value from FIFO
uint8_t fifo_pop() {
    if (count > 0) {
        uint8_t val = fifo[tail];
        tail = (tail + 1) % DEPTH;
        count--;
        return val;
    } else {
        printf("[C FIFO] pop attempted when empty!\n");
        return 0xFF;
    }
}

// Query if FIFO is empty
bool fifo_is_empty() {
    return (count == 0);
}

// Query if FIFO is full
bool fifo_is_full() {
    return (count == DEPTH);
}

// Optional: Reset FIFO
void fifo_reset() {
    head = 0;
    tail = 0;
    count = 0;
}
