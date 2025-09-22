# Clube da Areia

## Para iniciar

Para usar o sistema você deve executar:

Backend:

```bash
    git clone https://gitlab.com/andresonax/appgravou.git
    cd clube-da-areia
    cd backend
    npm i
    npm run dev
```

Em outro terminal, Frontend:

```bash
    cd clube-da-areia
    cd frontend
    flutter run
```

## A ideia do projeto

O clube da areia se trata de um sistema de locação de quadras esportivas. Para este sistema existem duas opções distintas: O uso genérico por todas empresas incluídas e o uso personalizado por empresas que contratem tal serviço.

## Sobre o projeto

O sistema é feito utilizando no frontend o Framework Flutter com a linguagem Dart e o Framework Express na linguagem Javascript no backend.

Recomenda-se o uso do MySQL Workbench para a visualização dos dados do banco de dados relacional.

O frontend do projeto é feito usando os padrões MVC e Repository. Isso significa que as requisições para o servidor devem ser feitas em arquivos Repository e o intermédio entre as páginas (views) e os Repositories deve ser feito por meio dos Controllers.

## Organização de Pastas

O backend possui as principais rotas nas pastas src/routes, excetuando a pasta src/auth de autenticação e src/pwRecovery para a recuperação de senha. Ainda na pasta src do backend existe o arquivo index.js, responsável pela exportação das rotas criadas. No frontend, as principais pastas se encontram na pasta lib/src, que contém common_widgets, com widgets reaproveitáveis, constants, para variáveis constantes que possam ser alteradas no futuro, routing para rotas e utils para funções reaproveitáveis. As principais pastas de lib/src são as features, com as views e controllers de cada feature do sistema e repository, com os repositories correspondentes.

## Para subir alterações

para subir alterações, certifique que você está na branch dev com o comando:

```bash
    git checkout dev
    git add .
    git commit -m "MENSAGEM DE ENVIO"
    git push origin dev
```






