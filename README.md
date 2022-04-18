# Cloud native 
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

### Kubeval
- Efetua validação dos manifestos do kubernetes
- No exemplo abaixo, ele verifica se existe alguma propriedade desconhecida, pelo schema kubernetes com base em sua versão

```
kubeval --strict -d k8s
```
