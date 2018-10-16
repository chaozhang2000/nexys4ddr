#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "memorymap.h"


// This is a small demo program that waits in an infinite loop for incoming
// Ethernet frames. It prints the first 16 bytes of each frame.
// The purpose of this program is to test the synchronization between the CPU
// and the Rx DMA.

// This variable is only used during simulation, to test the arbitration
// between CPU and Ethernet while writing to memory.
uint8_t dummy_counter;

// Start of receive buffer.
uint8_t *pBuf;

// Length of current frame (including frame header)
uint16_t frmLen;

// Index variable
uint8_t  i;

void main(void)
{
   dummy_counter = 0;

   // Allocate receive buffer. This will never be free'd.
   // Using malloc (rather than a globally allocated array) avoids a call to
   // memset generated by the compiler, thereby reducing simulation time.
   // The size must be at least an entire Ethernet frame including 2-byte header.
   pBuf = (uint8_t *) malloc(1516);

   // Verify that Rx DMA is disabled from start.
   assert(MEMIO_CONFIG->ethRxdmaEnable == 0);

   // Configure Ethernet DMA. May only be done while Rx DMA is disabled.
   MEMIO_CONFIG->ethRxdmaPtr = (uint16_t) pBuf;
 
   // Wait for data to be received, and print to the screen
   while (1)
   {
      // Indicate to Rx DMA that we are ready to receive a frame.
      MEMIO_CONFIG->ethRxdmaEnable = 1;

      // Wait until an ethernet frame has been received
      while (MEMIO_CONFIG->ethRxdmaEnable == 1)
      {
         dummy_counter += 1;   // This generates a write to the main memory.
      }

      // Length of this frame in bytes.
      frmLen = *((uint16_t *) pBuf);  // Read value as little-endian

      // Show the pointer locations of the received Ethernet frame.
      printf("%04x:", frmLen);

      // Show the 14 bytes MAC header.
      for (i=2; i<16; ++i)
      {
         printf("%02x", pBuf[i]);
      }
      printf("\n");
   }

} // end of main
