# Analisador Léxico

Para executar o analisador léxico para a linguagem c-, abrir um terminal na
pasta do projeto e rodar os seguintes comandos:

```
$ flex cminus.l && gcc -c *.c && gcc -o cminus *.o -lfl && ./cminus test
```

# Analisador Sìntático

Para executar o analisador sintático para a linguagem c-, abrir um terminal na
pasta do projeto e rodar os seguintes comandos:

```
$ bison -d cminus.y && flex cminus.l && gcc -c *.c && gcc -o cminus *.o -lfl && ./cminus test
```