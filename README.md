# Cloud native 
- projetos participantes
  - catalog-service
  - order-service-v2 
  - edge-service
  - dispatcher-service
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
- programação reativa é antiga, em java ficou famosa graças a especificação REACTIVE STREAMS e suas implementações, como: project reactor, rxjava e vertx.

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

##### Resilience4j  e padrão circuit breaker
- circuit breaker funciona da seguinte forma:
  - quando algum componente começa a apresentar falha, seja devido a comunicação externa, o circuito de abre
  - com circuito aberto, o componente não é mais executado e sim um fallback , caso esteja configurado
  - após um tempo o circuito fica semi-aberto, para validar se o componente voltou a funcionar
  - caso tenha sucesso na requisições, circuito volta para fechado, ao contrário, volta a ficar aberto  
- o resilience4j é uma alternativa ao antigo hystrix 
- podemos integra-lo ao circuit breaker do spring, adicionando a dependencia abaixo e realizando algumas configurações como:
```
implementation 'org.springframework.cloud:spring-cloud-starter-circuitbreaker-reactor-resilience4j'
```
```
resilience4j:
  circuitbreaker:
    configs:
      default:
        slidingWindowSize: 20 #20 chamadas serao consideradas dentro da janela para analise
        permittedNumberOfCallsInHalfOpenState: 5 # 5 chamadas no estado meio aberto
        failureRateThreshold: 50 #das 20, 10 veio com erro, circuito é aberto
        waitDurationInOpenState: 15000 #com o circuito aberto por 15s, faz transição para o semiaberto
  timelimiter:
    configs:
      default:
        timeoutDuration: 5s

```
- a imagem abaixo demonstra o funcionamento dos recursos funcionando em conjunto

![Alt text](https://github.com/fabriciolfj/cloud-native-v2/blob/main/my-java-image/CH09_F05_Vitale.png)

#### Limitação de taxa
- Padrão utilizado para controlar o tráfego enviado ou recebido de um aplicativo
- Pode-se efetuar o controle do lado do servidor ou cliente.
  - do lado do cliente, controlamos o número de solicitações a outros serviços por um período
  - do lado do servidor, controlamos o número de solicitações recebidas por um serviço

- do lado do servidor, o padrão é util em caso de gateways, para controlar a quantidade de solicitações, para isso utilizaremos o Spring cloud gateway com redis

##### Limitador de requisição via redis
- Base-se no algoritmo token bucket
  - cada usuario recebe um bucket com um volume de tokens, com base na taxa de reabastecimento
  - cada bucket tem uma capacidade máxima
  - quando o usuário faz uma solicitação, um token e retirado do bucket
  - para nosso caso, onde cada solicitação custe um token
- obs -> dentre os patterns de resiliência, o limitador de taxa e aplicado primeiro (na frente do circuit breaker e retry)


## Utilizando eventos
- existem alguns tipos de acoplamentos, como:
  - implantação: com o uso de uma interface rest, o cliente ou servidor, não precisa conhecer como é feita a respostas ou solicitação, isso é transparente,
  - temporal: para compor uma reposta, um serviço precisa que outro esteja up, para mitigar esse risco podemos utilizar a comunicação via evento. 

## Segurança
### OIDC (openid connect)
- é um protocolo que permite a uma aplicativo cliente, verifique a identidade de um usuário, com base na autenticação realizada por uma parte confiável e recupere as informações do usuário.
- nesse contexto tempos 3 atores: authorization server, dono do recurso e o aplicativo cliente.
- oidc é uma camada acima do auth2, que lida com a autenticação e o oauth2 lida com a autorização

### Utilizando o oauth2Login()
- Usuario acessa o endpoint protegido
- aplicação redireciona ao authorization manager,
- efetua o login
- é redirecionado a aplicação com o token e esta o armazena, com um cookie de sessão (que e atrelado a este token dentro da app)
- próximas requisições a aplicação utiliza o cookie de sessão para identificar o contexto do usuario (aonde encontra-se o token)

#### Token
- id token: contem informações de autenticação do usuário
  - é utilizado pelo serviço gateway, afim de configurar o contexto para a sessão do usuário e disponibilizar por meio do objeto OIDCUser
- token de acesso: contem informações de autorização do usuário
  - não é utilizado pelo gateway, pois o mesmo é apenas repassado aos serviços downstream, fica filter (procedimento conhecido como token relay) 


## Observabilidade
- analisar o comportamento da aplicação, atráves de métricas, logs, traces
- prever tendências de falhas com base em comportamento histórico
obs: uma aplicação nativa na nuvem, precisa enviar os logs gerados a um agente externo

### Uso do micrometer
- O spring boot expõe as metricas da aplicação através do actuator, no entanto caso queira expor para alguma ferramenta, deve-se fazer uso da lib da mesma.
- o micrometer pega os dados gerados pelo actuator e o expõe em um formato que o prometheus consegui entender
- devido ao grando uso do micrometer, seu padrão de exibição de métricas foi adotado pelo openTelemetrics/cncf

### Rastreabilidade
- ver o percurso para atender uma solicitação
- atualmente o formato e protocolo para gerar e propagar o rastreamento, é o openTelemetry
- podemos utilizar diretamente ou fazer uso de uma fachada como o spring sleuth 
- ferramenta em uso neste projeto, para armazenar e demonstrar os rastreamentos é o TEMPO

### Testes
- para testar a resiliência da aplicação: https://codecentric.github.io/chaos-monkey-spring-boot/
- para testar a performance da aplicação: https://gatling.io/
