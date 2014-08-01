STM_DRIVER_PATH = $(HOME)/Documents/archives/STM32F4xx_DSP_StdPeriph_Lib_V1.3.0/Libraries/STM32F4xx_StdPeriph_Driver
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

CFLAGS  = -g3 -O0 -Wall -Tstm32_flash.ld 
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += $(foreach inc,$(INC),-I$(inc))

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
