import matplotlib.pyplot as plt

words = ["manzana", "manzana", "hola", "si", "manzana"]

# Guardar palabras en un txt
#with open("cache/text.txt", "w") as file:
#    for word in words:
#        file.write(word + "\n")

content = ""

# Obtener informacion del resultado del archivo arm
with open("cache/result.txt", "r") as file:
    content = file.read()

data = ord(content[8])

# Tokenizar datos y guardarlos
wordsData = []
freqData = []
tokenContent = content.split('\n')
tokenContent.pop()  # Elimina basura

for token in tokenContent:
    data = token.split(' ')
    wordsData.append(data[0])
    freqData.append(ord(data[1]))


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


