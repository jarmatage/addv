#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#define DEPTH 16

static uint8_t fifo[DEPTH];
static int waddr = 0;  // write index
static int raddr = 0;  // read index
static int count = 0;

// Push value into FIFO
void push(uint8_t data) {
    if (count < DEPTH) {
        fifo[waddr] = data;
        waddr = (waddr + 1) % DEPTH;
        count++;
        printf("[C FIFO] pushed: %d, new count = %d\n", data, count);
    } else {
        printf("[C FIFO] push attempted when full!\n");
    }
}

// Pop value from FIFO
uint8_t pop() {
    if (count > 0) {
        uint8_t val = fifo[raddr];
        raddr = (raddr + 1) % DEPTH;
        count--;
        printf("[C FIFO] popped: %d, new count = %d\n", val, count);
        return val;
    } else {
        printf("[C FIFO] pop attempted when empty!\n");
        return 0xFF;
    }
}

// Query if FIFO is empty
bool is_empty() {
    return (count == 0);
}

// Query if FIFO is full
bool is_full() {
    return (count == DEPTH);
}

// Optional: Reset FIFO
void reset() {
    waddr = 0;
    raddr = 0;
    count = 0;
}
