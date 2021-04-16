import zlib

f_in = open('keccak_in.txt', 'r')
f_out = open('keccak_in_32_bit.txt', 'w')

Lines = f_in.readlines()

f_out.write(Lines[0])

n = 24833
for x in range(1,n):
	str = Lines[x]
	if str == ("-\n"):
		f_out.write('-\n')
	else:
		f_out.write(str[8:16] + '\n')
		f_out.write(str[0:8] + '\n')
		
f_out.write('.\n')
	
