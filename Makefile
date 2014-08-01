# The driver is compiled in different ways, depending on what chip we are
# compiling for.
STM_CHIP_SET    = STM32F40_41xxx
STM_DRIVER_PATH = $(HOME)/Documents/archives/STM32F4xx_DSP_StdPeriph_Lib_V1.3.0/Libraries/STM32F4xx_StdPeriph_Driver
STM_DRIVER_HDRS_STD = stm32f4xx_adc.h \
					  stm32f4xx_crc.h \
					  stm32f4xx_dbgmcu.h \
					  stm32f4xx_dma.h \
					  stm32f4xx_exti.h \
					  stm32f4xx_flash.h \
					  stm32f4xx_gpio.h \
					  stm32f4xx_i2c.h \
					  stm32f4xx_iwdg.h \
					  stm32f4xx_pwr.h \
					  stm32f4xx_rcc.h \
					  stm32f4xx_rtc.h \
					  stm32f4xx_sdio.h \
					  stm32f4xx_spi.h \
					  stm32f4xx_syscfg.h \
					  stm32f4xx_tim.h \
					  stm32f4xx_usart.h \
					  stm32f4xx_wwdg.h \
					  misc.h
STM_DRIVER_HDRS_F40_41 = stm32f4xx_cryp.h \
						 stm32f4xx_hash.h \
						 stm32f4xx_rng.h \
						 stm32f4xx_can.h \
						 stm32f4xx_dac.h \
						 stm32f4xx_dcmi.h \
						 stm32f4xx_fsmc.h
STM_DRIVER_HDRS_F427_437 = stm32f4xx_cryp.h \
						   stm32f4xx_hash.h \
						   stm32f4xx_rng.h \
						   stm32f4xx_can.h \
						   stm32f4xx_dac.h \
						   stm32f4xx_dcmi.h \
						   stm32f4xx_dma2d.h \
						   stm32f4xx_fmc.h \
						   stm32f4xx_sai.h
STM_DRIVER_HDRS_F429_439 = stm32f4xx_cryp.h \
						   stm32f4xx_hash.h \
						   stm32f4xx_rng.h \
						   stm32f4xx_can.h \
						   stm32f4xx_dac.h \
						   stm32f4xx_dcmi.h \
						   stm32f4xx_dma2d.h \
						   stm32f4xx_fmc.h \
						   stm32f4xx_ltdc.h \
						   stm32f4xx_sai.h

STM_DRIVER_SRCS = $(wildcard $(STM_DRIVER_PATH)/src/*.c) 
STM_DRIVER_OBJS = $(STM_DRIVER_SRCS:$(STM_DRIVER_PATH)/src/%.c=objs/%.o)
STM_DRIVER_INC  = $(STM_DRIVER_PATH)/inc
STM_DRIVER_DEP  = inc/stm32f4xx_conf.h inc/stm32f4xx.h $(wildcard $(STM_DRIVER_INC)*.h)

CMSIS_PATH = $(HOME)/Documents/archives/CMSIS

PROJ_INC_PATH = inc

INC  = $(PROJ_INC_PATH) $(CMSIS_PATH)/Include $(STM_DRIVER_INC)

PROJ_SRCS_PATH = src
PROJ_SRCS = $(wildcard $(PROJ_SRCS_PATH)/*.c)
PROJ_OBJS = $(patsubst $(PROJ_SRCS_PATH)/%, objs/%, $(addsuffix .o, $(basename $(PROJ_SRCS))))

PROJ_SRCS_ASM = $(wildcard $(PROJ_SRCS_PATH)/*.s)
PROJ_OBJS_ASM = $(patsubst $(PROJ_SRCS_PATH)/%, objs/%, $(addsuffix .o, $(basename $(PROJ_SRCS_ASM))))

PROJ_DEP = $(wildcard $(PROJ_INC_PATH/*.h))

OBJS = $(STM_DRIVER_OBJS) $(PROJ_OBJS) $(PROJ_OBJS_ASM)

BIN = main.elf

# building for stm32f407 which is part of the family of chips with similar
# peripherals, therefore the following is defined
DEFS    = STM32F40_41xxx #STM32F429_439xx
CFLAGS  = -g3 -O0 -Wall -Tstm32_flash.ld 
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += $(foreach inc,$(INC),-I$(inc))
CFLAGS += $(foreach def,$(DEFS),-D$(def))

CC = arm-none-eabi-gcc

OCD	= sudo openocd \
		-f /usr/share/openocd/scripts/board/stm32f4discovery.cfg

driver: $(STM_DRIVER_OBJS)

proj: $(PROJ_OBJS)

# compile stm driver
$(STM_DRIVER_OBJS): objs/%.o: $(STM_DRIVER_PATH)/src/%.c $(STM_DRIVER_DEP)
	$(CC) -c $(CFLAGS) $< -o $@

# compile asm
$(PROJ_OBJS_ASM): objs/%.o: $(PROJ_SRCS_PATH)/src/%.s $(PROJ_DEP)
	$(CC) -c $(CFLAGS) $< -o $@

# compile c
$(PROJ_OBJS): objs/%.o: $(PROJ_SRCS_PATH)/src/%.c $(PROJ_DEP)
	$(CC) -c $(CFLAGS) $< -o $@

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

flash: $(BIN)
	$(OCD) -c init \
		-c "reset halt" \
	    -c "flash write_image erase $(BIN)" \
		-c "reset run" \
	    -c shutdown
