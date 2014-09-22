ifneq ($(SRC),)
VPATH=$(SRC)
endif

CFLAGS += -I. -I$(SRC) -Wall -std=c99 -D_BSD_SOURCE=1 -D_GNU_SOURCE=1

all: shutdown_button

shutdown_button: shutdown_button.o
	$(CC) -o $@ $^

clean:
	rm -rf *.o $(all)
