// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats - STM32L432KC_DAC.c
// December 2, 2025
// Provides initialization and necessary functions for initializing DAC and outputting sine LUT values

#include "STM32L432KC.h"
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_DAC.h"


void initDAC(){
  // Enable DAC clock
  RCC->APB1ENR1 |= RCC_APB1ENR1_DAC1EN;

  // Disable channel 1 while configuring
  DAC1->CR &= ~DAC_CR_EN1;

  // Normal mode, buffer enabled, connected to external pin
  // MODEx = 000 : buffer ON, connected to pin
  DAC1->MCR &= ~DAC_MCR_MODE1;   // clear MODEx[2:0] for channel 1
  
  // Trigger from TIM7
  DAC1->CR &= ~DAC_CR_TEN1;

  // No DMA
  DAC1->CR &= ~DAC_CR_DMAEN1;
  DAC1->CR &= ~DAC_CR_DMAUDRIE1;

  // Enable DAC channel 1
  DAC1->CR |= DAC_CR_EN1;
  }


// Write to DAC register
void DACwrite(uint16_t value) {
  // Cap value at 12 bits
  value &= 0x0FFF;
  
  // Write value to DAC register
  DAC1->DHR12R1 = value;
}