# Makefile
IMAGE_1 = bdance
IMAGE_2 = face

# Default target
all: clean copy

# Clean target: delete the specified images
clean:
	@echo "Deleting images..."
	rm -f *.bmp

# Copy target: copy new images into the folder
copy:
	@echo "Copying images..."
	cp ./BMP_files/$(IMAGE_1)_original.bmp $(IMAGE_1).bmp
	cp ./BMP_files/$(IMAGE_2)_original.bmp $(IMAGE_2).bmp

# Phony targets to ensure the commands are run every time
.PHONY: all clean copy
