This folder contains all files needed to create a project Vivado that can a NewHope encryption/decryption simulation using Trivium as the PRNG. The steps to run the simulation are:

1) Create a new vivado project and include all *.v files as design sources (optionaly you can exclude the tb_* file and include later as a simulation source).
2) Add the con1.xdc file as a constraint. This file contains a constraint for a 100 MHz clock to verify it meets timing requirements.
3) On line 161 of tb_newhope_trivium, change the test vector path to math the location of the newhope_tv.txt file.

The simulation can now be run. The simulation read in the test vectors from newhope_tv.txt which provide the 32-byte seed to the key generator and the 
32-byte coin to the encrypter. The key generator generates the public and private keys, then the test bench transfers the public key to the encrypter and 
loads in the message and coin. Once the encrypter is finsihed, the test bench transfers the secret key and resulting ciphertext to the decrypter, the 
output of the decrypter is compared with the input to the encrypter to check correctness. 
