// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats - main.c
// December 2, 2025
// This file combines all frequency modulation, DAC protocols, and interrupt handling to produce good audio to feed into the amplifier

#include <stdio.h>
#include <stdlib.h>
#include "STM32L432KC.h"
#include "STM32L432KC_DAC.h"
#include "STM32L432KC_FLASH.h"
#include "STM32L432KC_TIM.h"
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
#include "stm32l432xx.h"
#include "STM32L432KC_RCC.h"
#include "main.h"

// System Parameters
#define MIN_FREQ   200   // Min output frequency = 200 Hz
#define MAX_FREQ   2000  // Max output frequency = 2000 Hz
#define SPAN       1800  // MAX_FREQ - MIN_FREQ
#define DDS_FREQ   96096 // 32 MHz/333 (refer to TIM7 script)
#define MAX_TUNING 600   // Max tuning word value from FIR (506) + buffer 
#define DDS_K      44695 // Gain factor for converting frequency to phase increment (2^32/DDS_FREQ)

// Variables
volatile uint32_t phase_acc = 0;      // Phase accumulator
volatile uint32_t phase_inc = 0;      // Phase incrementor
volatile uint16_t sample;             // Sample to feed into DAC
volatile uint8_t  fpga_done = 0;      // Flag to initiate SPI
volatile uint8_t  audio_enable = 0;   // Enables audio based on trigger
volatile uint8_t  trigger_enable = 0; // Trigger for debouncing
volatile uint8_t  debounce = 0;       // Check to see if trigger is still debouncing
         uint8_t  spi_samples[4];     // Storage for 4 SPI transactions
         uint32_t tuning_word;        // Sum of transactions
         uint32_t tuning_word_adjust; // Updated tuning word (bit-shift corrected)

int main(void) {
  // Configure 64 MHz PLL clock
  configureFlash();
  configureClock();

  // Configure GPIO ports
  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);

  // Set Done pin read from FPGA
  pinMode(PA6, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD6, 0b10); // Set PA6 as pull-down

  // Set Trigger pin from scanner
  pinMode(PA8, GPIO_INPUT);
  GPIOA->PUPDR |= _VAL2FLD(GPIO_PUPDR_PUPD8, 0b01); // Set PA8 as pull-up

  // Set DAC output
  pinMode(PA4, GPIO_ANALOG);
  GPIOA->PUPDR &= ~GPIO_PUPDR_PUPD4;

  // Enable SYSCFG for RCC
  RCC->APB2ENR |= RCC_APB2ENR_SYSCFGEN;

  // Configure EXTICR for FPGA Done trigger (PA6) and button trigger (PA8)
  SYSCFG->EXTICR[2] |= _VAL2FLD(SYSCFG_EXTICR2_EXTI6, 0b000); // PA6
  SYSCFG->EXTICR[3] |= _VAL2FLD(SYSCFG_EXTICR3_EXTI8, 0b000); // PA8

  // Enable global interrupts:
  __enable_irq();

  // PA6 and PA8 Mask bit
  EXTI->IMR1 |= (1 << gpioPinOffset(DONE_PIN)); // configure the mask bit PA6
  EXTI->IMR1 |= (1 << gpioPinOffset(TRIG_PIN)); // configure the mask bit PA8

  // Enable edge triggers
  EXTI->RTSR1 |= (1 << gpioPinOffset(DONE_PIN)); // rising edge PA6
  EXTI->FTSR1 |= (1 << gpioPinOffset(TRIG_PIN)); // falling edge PA8

  // Turn on EXTI and TIM7 interrupts in NVIC_ISER
  NVIC->ISER[0] |= (1 << EXTI9_5_IRQn);
  NVIC_EnableIRQ(TIM7_IRQn);

  // Initialize DAC
  initDAC();

  // Initialize SPI
  initSPI(0b100, 1, 0);

  // Initialize TIM7
  RCC->APB1ENR1 |= RCC_APB1ENR1_TIM7EN;
  initTIM(TIM7);

  // Initialize TIM6 (for debounce delays)
  RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;
  initTIM(TIM6);

  while(1) {
    // PA6 interrupt triggered, FPGA FIR filter ready to send tuning word
    if(fpga_done == 1) {
      fpga_done = 0;
      
      // Execute 4 SPI transactions to get full 32-bit tuning_word on MCU
      digitalWrite(SPI_CE, 0);
      for(int i = 0; i < 4; i++) {
        spi_samples[i] = spiReceive(0);
      }
      digitalWrite(SPI_CE, 1);

      // Confirm all SPI transactions are completed and create adjusted tuning word
      while(SPI1->SR & SPI_SR_BSY); 
      tuning_word = (uint32_t) (spi_samples[0] << 24 | spi_samples[1] << 16 | spi_samples[2] << 8 | spi_samples[3]);
      tuning_word_adjust = tuning_word >> 16;
      
      // Calculate phase increment with the tuning word
      uint32_t scaled = (uint32_t) ((tuning_word_adjust * SPAN) / MAX_TUNING);
      uint32_t fout = MIN_FREQ + scaled;

      // Cap output frequencies at max and min
      if(fout < MIN_FREQ) fout = MIN_FREQ;
      if(fout > MAX_FREQ) fout = MAX_FREQ;

      phase_inc = (uint32_t) fout*DDS_K;
    }

    // Check if clean trigger is registered, toggle udio output enable, debounce
    if(trigger_enable) {
      trigger_enable = 0;
      audio_enable ^= 1;
      while(!digitalRead(TRIG_PIN));
      delay_millis(TIM6, 20);
      
      if(digitalRead(TRIG_PIN)){
        // Clear any pending EXTI flag on PA8 (if bounce occurred while masked)
        EXTI->PR1 |= (1 << gpioPinOffset(TRIG_PIN));

        // Re-enable EXTI on PA8
        EXTI->IMR1 |= (1 << gpioPinOffset(TRIG_PIN));

        debounce = 0;
      }
    }
  }
}


// TIM7 Interrupt Handler
void TIM7_IRQHandler(void) {
  // Clear interrupt flag
  clear_TIM_interrupt(TIM7);
  
  if(audio_enable) {
    // Increment the phase
    phase_acc += phase_inc;

    // Get two indexes, one right after the other for interpolation
    uint16_t ddsindex = (uint16_t) (phase_acc >> 24);
    uint16_t ddsindex2 = (uint16_t) ((ddsindex + 1) & 0xFF);

    // Fraction between current LUT index and the next
    uint16_t fraction = (uint16_t)((phase_acc >> 16) & 0xFF);

    // Get the signals from the LUT using both indexes
    uint32_t signal1 = dds_sin_lut[ddsindex];
    uint32_t signal2 = dds_sin_lut[ddsindex2];

    // Slope between two adjacent LUT values
    int32_t difference = (int32_t) signal2 - (int32_t) signal1;

    // Interpolated waveform formula
    uint32_t samp = signal1 + ((difference * (int32_t)fraction) >> 8);

    // Center the sample around 0 and allow DAC to output sample
    int16_t centered = (int16_t) samp - 2048;
    sample = (uint16_t) 2048 + centered;
  }
  else {
    sample = 2048;
  }

  // Output on DAC
  DACwrite(sample);
}


// Done Pin Interrupt Handler
void EXTI9_5_IRQHandler(void) {
  if (EXTI->PR1 & (1 << DONE_PIN)) {
    // Set an SPI trigger
    fpga_done = 1;
  
    // Reset PA6 interrupt flag
    EXTI->PR1 |= (1 << DONE_PIN);
  }

  if (EXTI->PR1 & (1 << TRIG_PIN)) {
    // Reset PA8 interrupt flag
    EXTI->PR1 |= (1 << TRIG_PIN);

    // Check that signal is not in debouncing
    if(!debounce) {
      // Clean trigger is registered, debounce enabled
      trigger_enable = 1;
      debounce = 1;

      // Turn off masking to avoid confounding interrupts
      EXTI->IMR1 &= ~(1 << gpioPinOffset(TRIG_PIN));
    }
  }
}