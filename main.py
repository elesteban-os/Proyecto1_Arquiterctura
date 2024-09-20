import matplotlib.pyplot as plt
import re
import time
import os

words = []

text = ""

# Abrir texto y leerlo
with open("text.txt", "r") as file:
    text = file.read()

# --- Procesar texto (tokenizarlo, eliminar caracteres especiales) ---
# Quitar caracteres especiales con expresiones regulares (caracteres como a hasta z y espacio)
text = re.sub(r'[^a-zA-Z ]', '', text)


# Quitar mayusculas
text = text.lower()

# Separar por espacio (tokenizar)
words = text.split(" ")

print(words)

# Escribir archivo de text_tokens
i = 0
lenwords = len(words)
with open('cache/text_tokens.txt', 'w') as file:
    for i in range(lenwords):
        file.write(words[i])
        if (i + 1 != lenwords):
            file.write('\n')

# Ejecutar comando para correr el ejecutable ensamblador
os.system('./words')

# Obtener informacion del resultado del archivo arm
content = ""
with open("cache/result.txt", "r") as file:
    content = file.read()

# Tokenizar datos y guardarlos
wordsData = []
freqData = []
tokenContent = content.split('\n')
tokenContent.pop()  # Elimina basura

print(tokenContent)

for token in tokenContent:
    data = token.split(' ')
    wordsData.append(data[0])
    freqData.append(ord(data[1]) - 32)


# Graficar 
bars = plt.bar(wordsData, freqData, color='skyblue')

# Colocar numero sobre barra
for bar in bars:
    barvalue = bar.get_height()
    plt.text(bar.get_x() + bar.get_width() / 2, barvalue, str(barvalue), ha='center', va='bottom')

plt.title('Histograma de palabras')
plt.xlabel('Palabras', fontweight='bold')
plt.ylabel('Frecuencia', fontweight='bold')

plt.show()


