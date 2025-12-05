// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats - STM32L432KC_SPI.c
// Source code for SPI functions

// This file initializes the SPI register on the MCU and 

#include "STM32L432KC_SPI.h"
#include "STM32L432KC_RCC.h"
#include "stm32l432xx.h"
#include "STM32L432KC.h"
#include "STM32L432KC_GPIO.h"


/* Enables the SPI peripheral and intializes its clock speed (baud rate), polarity, and phase.
      -- br: (0b000 - 0b111). The SPI clk will be the master clock / 2^(BR+1).
      -- cpol: clock polarity (0: inactive state is logical 0, 1: inactive state is logical 1).
      -- cpha: clock phase (0: data captured on leading edge of clk and changed on next edge, 
            1: data changed on leading edge of clk and captured on next edge)
   Refer to the datasheet for more low-level details. */ 
void initSPI(int br, int cpol, int cpha){

    // Turn on GPIOA and GPIOB clock domains (GPIOAEN and GPIOBEN bits in AHB1ENR)
    RCC->AHB2ENR |= (RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN);
    
    RCC->APB2ENR |= RCC_APB2ENR_SPI1EN; // Turn on SPI1 clock domain (SPI1EN bit in APB2ENR)

    // Initially assigning SPI pins
    pinMode(SPI_SCK, GPIO_ALT); // SPI1_SCK
    pinMode(SPI_MISO, GPIO_ALT); // SPI1_MISO
    pinMode(SPI_MOSI, GPIO_ALT); // SPI1_MOSI
    pinMode(SPI_CE, GPIO_OUTPUT); //  Manual CS

    // Set output speed type to high for SCK
    GPIOB->OSPEEDR |= (GPIO_OSPEEDR_OSPEED3);

    // Set to AF05 for SPI alternate functions
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL3, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL4, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL5, 5);
    
    // Set baud rate divider
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_BR, br); 
    
    // Set MCU as master device
    SPI1->CR1 |= SPI_CR1_MSTR;

    // Clear polarity and phase selections
    SPI1->CR1 &= ~SPI_CR1_CPOL;
    SPI1->CR1 &= ~SPI_CR1_CPHA;

    // Send MSB first
    SPI1->CR1 &= ~SPI_CR1_LSBFIRST;
    SPI1->CR1 &= ~SPI_CR1_SSM;

    // Update phase and polarity with input selections
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPHA, cpha);
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPOL, cpol);


    SPI1->CR2 |= _VAL2FLD(SPI_CR2_DS, 0b0111);
    SPI1->CR2 |= SPI_CR2_FRXTH;
    SPI1->CR2 |= SPI_CR2_SSOE;

    // Enable SPI
    SPI1->CR1 |= (SPI_CR1_SPE);
}


/* Transmits a character (1 byte) over SPI and returns the received character.
      -- send: the character to send over SPI
      -- return: the character received over SPI */
char spiSendReceive(char send){
  // Wait for TX buffer
  while(!(SPI_SR_TXE & SPI1->SR));

  // write to data register
  *(volatile char *) (&SPI1->DR) = send;
  
  // wait for RX register to be full
  while(!(SPI_SR_RXNE & SPI1->SR));

  // Store received data
  char received = (volatile char) SPI1->DR;

  return received; // character received over SPI
}

void spiSend(char addr, char send){
  // Send address
  spiSendReceive(addr);

  // Send what needs to be written
  spiSendReceive(send);
}

char spiReceive(char addr){
  // Send address
  spiSendReceive(addr);

  // Send null data
  char read = spiSendReceive(0x00);

  return read;
}