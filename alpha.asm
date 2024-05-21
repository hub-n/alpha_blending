# Author: Hubert Niewierowicz
# Description: The program, written in the RISC-V assembly language,
# takes in two bmp files and 'blends' the second file onto the first one. 
# It reads the file headers (assuming the most common 54 byte header size)
# and dynamically allocates heap memory for the pixel array. It then parses
# through the pixels and blends each one with a proportion of 50:50.
# BMP files of various and different sizes are supported, although they
# obviously must have an alpha channel (32 bpp).
# To reset the images use 'make'.

.eqv HEADER_SIZE 54

	.data
.align 4
res:	.space 2
image_1a:	.word 0x00000000
image_2a:	.word 0x00000000

header_1:	.space HEADER_SIZE
header_2:	.space HEADER_SIZE

blend_width:	.word 0x00000000
blend_height:	.word 0x00000000

fname_1:	.asciz "./alpha_blending/bdance.bmp"
fname_2:	.asciz "./alpha_blending/face.bmp"

	.text
main:	
	jal read_file_1
	jal read_file_2
	
	la t2, header_2	
	lh t2, 18(t2)	# width2 in t2
	la t1, header_1
	lh t1, 18(t1)	# width1 in t1
	sw t2, blend_width, a0
	bgt t1, t2, end_set_width
	sw t1, blend_width, a0
end_set_width:
	
	la t2, header_2	
	lh t2, 22(t2)	# height2 in t2
	la t1, header_1
	lh t1, 22(t1)	# height1 in t1
	sw t2, blend_height, a0
	bgt t1, t2, end_set_height
	sw t1, blend_height, a0
end_set_height:
	
	li s2, 0		# x of start pixel
	li s3, 0		# y of start pixel
	jal blend_alpha
	
end_blend_alpha:
	jal	save_file_1
	jal	save_file_2

exit:	li 	a7,10		# Terminate the program
	ecall



# read the first file
read_file_1:
	addi sp, sp, -4	# push $s1
	sw s1, 0(sp)
	
#open file
	li a7, 1024
        la a0, fname_1	#file name 
        li a1, 0	# flags: 0-read file
        ecall
	mv s1, a0      	# save_file the file descriptor

#read file
	li a7, 63
	mv a0, s1
	la a1, header_1
	li a2, HEADER_SIZE
	ecall
	
	la t1, header_1	
	lh t2, 18(t1)	# width in t2
	lh t1, 22(t1)	# height in t1

	mul t1, t1, t2	# image size in pixels
	slli t1, t1, 2	# image size in bytes
	addi t1, t1, 266
	
	mv a0, t1
	li a7, 9
	ecall
	sw a0, image_1a, t2	# store image1 address
	
	li a7, 63
	mv a0, s1
	lw a1, image_1a
	mv a2, t1
	ecall

	j close_read_file
	

# read the second file
read_file_2:
	addi sp, sp, -4	#push $s1
	sw s1, 0(sp)
	
#open file
	li a7, 1024
        la a0, fname_2	#file name 
        li a1, 0	#flags: 0-read file
	ecall
	mv s1, a0      	# save_file the file descriptor

#read file
	li a7, 63
	mv a0, s1
	la a1, header_2
	li a2, HEADER_SIZE
	ecall
	
	la t1, header_2	
	lh t2, 18(t1)	# width in t2
	lh t1, 22(t1)	# height in t1

	mul t1, t1, t2	# image size in pixels
	slli t1, t1, 2	# image size in bytes
	addi t1, t1, 266
	
	mv a0, t1
	li a7, 9
	ecall
	sw a0, image_2a, t2	# store image1 address
	
	li a7, 63
	mv a0, s1
	lw a1, image_2a
	mv a2, t1
	ecall

# close the file (used by both functions)
close_read_file:
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, 0(sp)	#restore s1
	addi sp, sp, 4
	jr ra
	
	

# save first file
save_file_1:
	addi sp, sp, -4	#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, fname_1	# file name 
        li a1, 1	# flags: 1-write file
	ecall
	mv s1, a0      	# save_file the file descriptor

#save file
	li a7, 64
	mv a0, s1
	la a1, header_1
	li a2, HEADER_SIZE
	ecall
	
	la t1, header_1	
	lh t2, 18(t1)	# width in t2
	lh t1, 22(t1)	# height in t1
	mul t1, t1, t2	# image size in pixels
	slli t1, t1, 2	# image size in bytes
	addi t1, t1, 266

	li a7, 64
	mv a0, s1
	lw a1, image_1a
	mv a2, t1
	ecall

	j close_saved_file

# save second file
save_file_2:
	addi sp, sp, -4	#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, fname_2	#file name 
        li a1, 1	#flags: 1-write file
        ecall
	mv s1, a0      	# save_file the file descriptor

#save file
	li a7, 64
	mv a0, s1
	la a1, header_2
	li a2, HEADER_SIZE
	ecall
	
	la t1, header_2	
	lh t2, 18(t1)	# width in t2
	lh t1, 22(t1)	# height in t1
	mul t1, t1, t2	# image size in pixels
	slli t1, t1, 2	# image size in bytes
	addi t1, t1, 266

	li a7, 64
	mv a0, s1
	lw a1, image_2a
	mv a2, t1
	ecall

# close the file (used by both functions) 
close_saved_file:
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, (sp)		#restore (pop) $s1
	addi sp, sp, 4
	jr ra
	
	
	
# set the RGBA value of a pixel at the given coordinates
# (0, 0) is the bottom left corner
# arguments:
# 	a0 - x coordinate
#	a1 - y coordinate
#	a2 - AARRGGBB - new pixel value
# return values:
#	none
set_pixel_1:
	lw t2, image_1a
	la t1, header_1	
	lh t1, 18(t1)	# width in t1
	slli t4, t1, 2	# bytes per row in t4
	
	j set_pixel

set_pixel_2:
	lw t2, image_2a
	la t1, header_2	
	lh t1, 18(t1)	# width in t1
	slli t4, t1, 2	# bytes per row in t4
	
set_pixel:
	mul t1, a1, t4 	# t1= y*BYTES_PER_ROW
	slli a0, a0, 2
	mv t3, a0		# $t3= 4*x
	add t1, t1, t3	# $t1 = 4x + y*BYTES_PER_ROW
	add t2, t2, t1	# pixel address 
	
	#set new color
	sb a2,(t2)	# store B
	srli a2,a2,8
	sb a2,1(t2)	# store G
	srli a2,a2,8
	sb a2,2(t2)	# store R
	srli a2,a2,8
	sb a2,3(t2)	# store alpha
	
	jr ra



# get the RGBA value of a pixel at the given coordinates
# (0, 0) is the bottom left corner
# arguments:
# 	a0 - x coordinate
#	a1 - y coordinate
# return values:
#	a0 - AARRGGBB - pixel value
get_pixel_1:
	lw t2, image_1a
	la t1, header_1	
	lh t1, 18(t1)	# width in t1
	slli t4, t1, 2	# bytes per row in t4
	
	j get_pixel

get_pixel_2:	
	lw t2, image_2a
	la t1, header_2	
	lh t1, 18(t1)	# width in t1
	slli t4, t1, 2	# bytes per row in t4

get_pixel:
	mul t1, a1, t4 	#t1= y*BYTES_PER_ROW
	
	slli a0, a0, 2
	mv t3, a0		# $t3= 4*x
	add t1, t1, t3	# $t1 = 4x + y*BYTES_PER_ROW
	add t2, t2, t1	# pixel address 
	
	#get color
	lbu a0,(t2)	# load B
	lbu t1,1(t2)	# load G
	slli t1,t1,8
	or a0, a0, t1
	lbu t1,2(t2)	# load R
        slli t1,t1,16
	or a0, a0, t1
	lbu t1,3(t2)	# load alpha
        slli t1,t1,24
	or a0, a0, t1
					
	jr ra
	
	

# blends the second image onto the first one
# arguments:
# 	s2 - start x coordinate
#	s3 - start y coordinate
# return values:
#	none
blend_alpha:
	# i-th x coordinate in s2
	# i-th y coordinate in s3
	# image1 pixel in s4
	# image2 pixel in s5
	# blended pixel in t5
	
	lw t6, blend_height
	bne s3, t6, parse_rows
	
	j end_blend_alpha
parse_rows:
	mv a0, s2
	mv a1, s3
	jal get_pixel_1
	mv s4, a0		# get image1 pixel
	
	slli s4, s4, 8
	srli s4, s4, 8
	li a0, 0x80000000
	or s4, s4, a0	# set image2 alpha
	
	mv a0, s2
	mv a1, s3
	jal get_pixel_2
	mv s5, a0		# get image2 pixel
	
	slli s5, s5, 8
	srli s5, s5, 8
	li a0, 0x80000000
	or s5, s5, a0	# set image2 alpha

# calculating alpha0
	srli s7, s4, 24	# get image1 alpha
	li s9, 255
	sub s9, s9, s7	# calculate 255 - alpha1
	
	srli s8, s5, 24	# get image2 alpha
	mul s8, s8, s9	# calculate alpha2 * (255 - alpha1)
	
	slli s7, s7, 8	# multiply image1 alpha by 256
	
	add s9, s7, s8	# calculate alpha0 * 256 [0 - 255]
	
	srli t5, s9, 8	# put alpha0 to blended pixel
	slli t5, t5, 8
	# alpha1 * 256 in s7
	# alpha2 * (255 - alpha1) in s8
	# alpha0 * 256 in s9
	
	# image1 R in s10
	# image2 R in s11
	slli s10, s4, 8	
	srli s10, s10, 24	# get image1 R
	slli s11, s5, 8	
	srli s11, s11, 24	# get image2 R
	
	mul s11, s11, s8	# calculate color2 * alpha2 * (255 - alpha1)
	mul s10, s10, s7	# calculate color1 * alpha1 * 256
	
	add s10, s10, s11
	div s10, s10, s9	# calculate blended R to s10
	add t5, t5, s10	# add R to blended pixel
	slli t5, t5, 8
	
	# image1 G in s10
	# image2 G in s11
	slli s10, s4, 16	
	srli s10, s10, 24	# get image1 G
	slli s11, s5, 16	
	srli s11, s11, 24	# get image2 G
	
	mul s11, s11, s8	# calculate color2 * alpha2 * (255 - alpha1)
	mul s10, s10, s7	# calculate color1 * alpha1 * 256
	
	add s10, s10, s11
	div s10, s10, s9	# calculate blended G to s10
	add t5, t5, s10	# add G to blended pixel
	slli t5, t5, 8
	
	# image1 B in s10
	# image2 B in s11
	slli s10, s4, 24	
	srli s10, s10, 24	# get image1 B
	slli s11, s5, 24	
	srli s11, s11, 24	# get image2 B
	
	mul s11, s11, s8	# calculate color2 * alpha2 * (255 - alpha1)
	mul s10, s10, s7	# calculate color1 * alpha1 * 256
	
	add s10, s10, s11
	div s10, s10, s9	# calculate blended B to s10
	add t5, t5, s10	# add B to blended pixel

# set pixel
	mv a0, s2		#x
	mv a1, s3		#y
	mv a2, t5
	jal set_pixel_1

# go to next pixel
	addi s2, s2, 1
	lw t6, blend_width	# width in t6
	bne s2, t6, blend_alpha
	
	sub s2, s2, t6
	addi s3, s3, 1

	j blend_alpha
