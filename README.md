# Cloud native 
- projetos participantes
  - catalog-service
  - order-service-v2 
- ferramenta para verificar vulnerabilidades https://github.com/anchore/grype
  - command: grype . (na raiz do projeto) 

### Configurando uma aplicação spring boot para desligamento gracioso
- Em um ambiente onde pods são destruídos e recriados, evitar indisponibilidade para o cliente, mesmo que seja por curto período, é desafiador.
- Spring fornece algumas configurações que nos ajudam nesse processo, como:
  - server.shutdown=graceful, termina todas as requisições/transações com base de dados em processamento e deixa de aceitar novas 
  - spring.lifecycle.timeout-per-shutdown-phase=30s, periodo de carência, ou seja, caso alguma requisição ou trasação demore mais de 30 segundos (no processo de desligamento gracioso), o servidor será desligado forçadamente.
  - um outro ponto, fora da aplicação, está no deployment desta que precisamos atrasar o desligamento, afim de dar tempo ao kubernetes de avisar ao cluster a destruição do pod envolvido.

```
      containers:
        - name: catalog-service
          image: catalog-service
          imagePullPolicy: IfNotPresent
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 5"]
```                
### Tilt
- Ferramenta que ajuda na geração de imagens e implantação de manifestos no seu ambiente local kubernetes.

### Octant
- Ferramenta que tem por objetivo inspecionar um cluste kubernetes
- Apos a instalação, apenas execute octant no terminal

### Kubeval
- Efetua validação dos manifestos do kubernetes
- No exemplo abaixo, ele verifica se existe alguma propriedade desconhecida, pelo schema kubernetes com base em sua versão

```
kubeval --strict -d k8s
```

## Aplicações reativas
- em aplicações imperativas funciona da seguinte forma: 
  - uma thread por solicitação
  - encadeia chamadas, ou seja, somente da a resposta quando todas as dependências sejam sanadas
- em aplicações reativas não envolve a alocação exclusiva de uma thread, mas o processo e realizado de forma assíncrona com base em eventos.
- uma das características das app reativas é o backpressure, onde o consumidor controla a quantidade de dados que consegui consumir.
- não confunda  app reativo como melhoria de performance, e sim, melhorar a escalabilidade e resiliência.
- programação reativa é antiga, em java ficou famosa graças a especificação REACTIVE STREAMS e sua simplementações, como: project reactor, rxjava e vertx.

### Projeto Reactor
- uma implementação da especificação reactive streams
- tudo é lidado como evento reativo e existe 2 tipos principais: Mono 0-1 evento e Flux 0-N eventos.

#### Clientes reativos
- dentro do projeto webflux, temos o webclient para realizar interações com outras apis externas, sem bloqueio
- da suporte a operadores reativos para resiliencia, como: timeout() - tempo limite, retryWhen() - retentativas e onError() - falha

#### Resiliencia
- resiliencia é a capacidade do aplicativo continuar disponível, diante de falhas.
- existem algumas estratégias para isolar o ponto de falha, que na maioria das vezes é a comunicação com mudo externo, por exemplo: chamada http para
outra aplicação.
- estratégias:
  - timeouts: para situações onde o tempo de respota da api servidora, não é o ideal.
  - retry: realizar retentativas com atraso crescente, diante de uma erro. Cuidado para operações que não são idempotentes. Para o reactor existe o retryWhen() e este é relevante a posição aonde o inseri (antes do timeout, o tempo definido no timeout e aplicado ao retry geral, por exemplo: 2 segundos para as 3 retentativas, já após o timeout, o tempo definido neste é aplicado a cada retry) 
  - fallbacks , retornar uma valor default ou uma informação relevante, caso o serviço dependente esteja inoperante ou uma falha aceitavel, como por exemplo um recurso inexistente. Em caso de falhas aceitáveis, não faz sentido executar um retry, por isso o fallback deve ser utilizado antes do retryWhen().
