# QA — 07_recursos_humanos

Gerado em 2026-07-26 21:35:30.

## Resumo

- linhas: 66.824
- colunas: 17
- células vazias (todas as colunas): 32.61%

## Checagens

Nenhum problema automático: as 20 checagens executadas passaram.

## Defeitos declarados no dicionário

Estes 7 defeito(s) estão declarados no dicionário e **não** são detectados pelas checagens automáticas acima. Um relatório limpo não significa uma tabela sem defeito.

- (munic_vinculos_estatutarios_adm_direta_i) Sem prefixo de fonte, sem sufixo de contagem; 'direta' = administracao direta, colide com qualquer outro uso de direta/indireta
- (munic_vinculos_clt_adm_direta_i) Idem (mesma familia: comissionados_direta, estagiarios_direta, sem_vinculo_permanente_direta e os seis analogos _indireta)
- (munic_vinculos_totais_adm_direta_i) 'total' sem qualificar que e ESTOQUE de vinculos ativos no ano de referencia da pesquisa Munic
- (munic_comissionados_adm_direta_prop) Abreviacao opaca; e uma PROPORCAO 0-1 (comissionados/total) convivendo com contagens na mesma tabela, sem sufixo de escala
- (munic_existe_administracao_indireta_cat) Nome sugere booleano; e character com 6 rotulos ('Sim','Nao','Recusa','Nao informou','Nao informado') e, so em 2011, uma CONTAGEM numerica - dois conceitos incompativeis no mesmo nome
- (munic_vinculos_totais_adm_indireta_i) Idem
- (munic_comissionados_adm_indireta_prop) Idem

