import struct

words = ["manzana", "manzana", "hola", "si", "manzana"]

# Guardar palabras en un txt
with open("cache/text.txt", "w") as file:
    for word in words:
        file.write(word + "\n")

# Guardar las palabras en un archivo binario
with open("cache/words.bin", "wb") as file:
    for word in words:
        file.write(struct.pack('I', len(word)))  # Guardar la longitud de la palabra
        file.write(word.encode('utf-8'))         # Guardar la palabra en sí

print(struct.pack('I', len(words[1])))