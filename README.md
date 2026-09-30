# TraceLens

TraceLens é um app de inspeção de tráfego HTTP para desenvolvimento, QA e depuração. Ele ajuda a investigar o que acontece nas comunicações de rede durante uma sessão, sem substituir ferramentas de telemetria ou monitoramento de produção.

## O que o app faz

O TraceLens reúne as requests capturadas em uma única tela e apresenta as informações necessárias para entender cada chamada: serviço, endpoint, método, status, duração, headers, body e métricas de rede quando disponíveis.

Com ele, é possível:

- acompanhar as requests da sessão atual;
- filtrar e localizar chamadas por serviço, endpoint ou status;
- consultar headers, bodies e métricas de cada request;
- definir escopos temporários de captura para uma sessão ou para a próxima request;
- exportar a sessão ou uma request nos formatos TXT e JSON;
- copiar ou exportar um comando `CURL - BFF` pronto para execução.

## Captura de requests

O app trabalha com dois níveis de detalhe. O modo `Metadata` registra URL, método, status e duração. O modo `Detalhes completos` também registra headers e body da request e da response.

Os escopos de captura permitem limitar a investigação a hosts ou caminhos específicos. Para uma mesma origem, a regra mais específica tem prioridade. As regras temporárias podem valer apenas para a próxima request ou permanecer durante a sessão atual.

## Visualização e investigação

Cada request mostra um resumo do serviço e do endpoint, além de abas para headers, body e métricas. O título do serviço pode refletir o nome técnico da rota ou um nome mais amigável, facilitando a leitura da lista de requests.

As métricas exibem informações como duração, tamanho transferido e dados de conexão quando esses dados forem fornecidos pela camada de rede.

## Exportações

O formato TXT gera um relatório de leitura rápida. O JSON preserva a estrutura dos dados para análise técnica e compartilhamento controlado.

Na tela de uma request, a opção `CURL - BFF` permite montar um comando direcionado ao BFF. O host é preenchido a partir do componente técnico e do ambiente selecionado, e pode ser editado. Também é possível informar um path intermediário entre o host e o endpoint, copiar o comando para a área de transferência ou exportá-lo em arquivo.

O comando preserva método, endpoint, query string, headers e body. Para que seja executável, ele usa o token Bearer original e exige que a request tenha sido capturada com detalhes completos.

## Privacidade e limites

Por padrão, dados sensíveis são mascarados na interface e nas exportações. A exportação `CURL - BFF` é uma exceção, pois inclui o token Bearer original para permitir a execução do comando. Compartilhe esse conteúdo apenas por canais aprovados.

O TraceLens mantém somente a sessão atual e remove os arquivos temporários de body quando a sessão é limpa, interrompida ou quando o app é iniciado. Os limites padrão são 1.000 transações, 5 MB por body e 100 MB de armazenamento temporário.

Como se destina a desenvolvimento e investigação, a captura não deve interromper ou bloquear a request original. Alguns tipos de sessão, bibliotecas de rede e detalhes de redirecionamento podem não ser observados.
