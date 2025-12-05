
#include "STM32L432KC.h"
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_DMA.h"


void initDMA() {
// Reset DMA1 Channel 2
    DMA1_Channel2->CCR  &= ~(0xFFFFFFFF);
    DMA1_Channel2->CCR  |= (_VAL2FLD(DMA_CCR_PL, 0b10) |
                            _VAL2FLD(DMA_CCR_MINC, 0b1) |
                            _VAL2FLD(DMA_CCR_CIRC, 0b1) |
                            _VAL2FLD(DMA_CCR_DIR, 0b1));
    
    // Set DMA source and destination addresses.
    // Source: Address of the character array buffer in memory.
    DMA1_Channel2->CMAR = _VAL2FLD(DMA_CMAR_MA, (uint32_t) &CHAR_ARRAY);

    // Dest.: USART data register
    DMA1_Channel2->CPAR = _VAL2FLD(DMA_CPAR_PA, (uint32_t) &(USART->TDR));

    // Set DMA data transfer length (# of samples).
    DMA1_Channel2->CNDTR  |= _VAL2FLD(DMA_CNDTR_NDT, CHAR_ARRAY_SIZE);
    
    // Select 4th option for mux to channel 2
    DMA1_CSELR->CSELR |= _VAL2FLD(DMA_CSELR_C2S, 4);

    // Enable DMA1 channel.
    DMA1_Channel2->CCR  |= DMA_CCR_EN;

    }