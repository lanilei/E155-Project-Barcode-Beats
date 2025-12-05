// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats
// STM32L432KC_DAC.h
// Header for DAC functions

#ifndef STM32L4_DAC_H
#define STM32L4_DAC_H

#include <stdint.h>
#include <stm32l432xx.h>

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void initDAC(void);
void DACwrite(uint16_t value);

#endif