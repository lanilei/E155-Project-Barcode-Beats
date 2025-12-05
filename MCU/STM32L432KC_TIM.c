// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats - STM32L432KC_TIM.c
// December 2, 2025
// This file provides initialization and helper functions for timer peripherals

#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"
#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>

void initTIM(TIM_TypeDef * TIMx){
  TIMx->PSC = 1;
  TIMx->ARR = 332;
  TIMx->CNT = 0;

  TIMx->CR1 |= TIM_CR1_ARPE;

  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;

  // Enable interrupts for timer 7
  TIMx->DIER |= TIM_DIER_UIE;

  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1

}

void delay_millis(TIM_TypeDef * TIMx, uint32_t ms){
  // Set prescaler to give 1 ms time base
  uint32_t psc_div = (uint32_t) ((SystemCoreClock/1e3));

  TIMx->PSC = psc_div;
  TIMx->ARR = ms;     // Set timer max count
  TIMx->EGR |= 1;     // Force update
  TIMx->SR &= ~(0x1); // Clear UIF
  TIMx->CNT = 0;      // Reset count

  while(!(TIMx->SR & 1)); // Wait for UIF to go high
}

void clear_TIM_interrupt(TIM_TypeDef * TIMx) {
  TIMx->SR &= ~TIM_SR_UIF;
}