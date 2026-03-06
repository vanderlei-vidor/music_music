# Release Notes 1.3.0

Data da release: 6 de marco de 2026  
Versao: `1.3.0+1`

## Play Console (PT-BR)

Melhoramos a estabilidade e a experiencia geral do app nesta versao:

- Padronizacao dos estados de tela em toda a biblioteca e playlists (`carregando`, `vazio`, `erro`).
- Mensagens de erro mais claras com acao de recuperacao (ex.: tentar novamente/reescanear).
- Melhorias de navegacao e consistencia visual entre Home, Biblioteca, Favoritas e Playlists.
- Base de observabilidade reforcada para diagnostico de problemas.
- Ajustes de manutencao para reduzir regressao em fluxos criticos do player.

## Web Release Summary (PT-BR)

Esta atualizacao foca em consistencia de UX e robustez operacional:

- Fluxos de estado de tela unificados para reduzir comportamento inconsistente.
- Melhor feedback em cenarios de biblioteca vazia e falhas de carregamento.
- Melhor base de logs para suporte tecnico e investigacao de erros.

## Internal QA Notes

- Validar estados `loading/empty/error` nas telas principais apos build release.
- Confirmar fluxo completo: Home -> Biblioteca -> Playlists -> Player.
- Confirmar que CTAs de recuperacao acionam o comportamento esperado.
