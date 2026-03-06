# Release Checklist 1.3.0 (Android/Web)

## 1. Pre-release (obrigatorio)

- [x] Confirmar versao no `pubspec.yaml` (`version: 1.3.0+N`).
- [x] Revisar changelog em `CHANGELOG.md` (`[1.3.0]`).
- [ ] Rodar qualidade local:
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [x] `flutter analyze`
  - [x] `flutter test`
- [ ] Validar padronizacao de estado de telas:
  - [ ] `loading` consistente em Home/Library/Playlists/Favorites/Player
  - [ ] `empty` com texto claro e CTA quando aplicavel
  - [ ] `error` com acao de recuperacao (`Tentar novamente`)
- [ ] Smoke test manual:
  - [ ] Home tabs e navegacao por rotas principais
  - [ ] Biblioteca completa, busca e filtros
  - [ ] Playlists (criar, listar, selecionar musicas)
  - [ ] Favoritas, recentes e mais tocadas
  - [ ] Player principal + mini player

## 2. Android (producao)

### Build e validacao
- [ ] `flutter build appbundle --release`
- [ ] Instalar AAB em trilha interna e validar fluxo completo.
- [ ] Verificar permissao de midia e leitura da biblioteca em Android 13+.
- [ ] Validar startup a frio e reabertura sem travamentos.

### Publicacao
- [ ] Atualizar notas da versao no Play Console com base no `CHANGELOG.md`.
- [ ] Confirmar politica de dados/permissoes.
- [ ] Promover para producao apos beta interno.

## 3. Web (producao)

### Build e deploy
- [ ] `flutter build web --release`
- [ ] Publicar `build/web` no hosting/CDN.
- [ ] Confirmar fallback SPA (`index.html`) e cache correto.

### Validacao
- [ ] Navegacao principal e busca sem regressao.
- [ ] Player funcionando com arquivos da web/local suportados.
- [ ] Teste em Chrome e Edge (desktop).

## 4. Observabilidade e suporte

- [ ] Testar exportacao de logs em `Sobre`.
- [ ] Validar que erros globais sao registrados via `AppLogger`.
- [ ] Definir canal de coleta de feedback das primeiras 72h.

## 5. Go/No-Go

- [x] `flutter analyze` sem issues.
- [x] `flutter test` sem falhas.
- [ ] Nenhum bug bloqueante aberto para fluxo de reproducao e biblioteca.
- [ ] Aprovacao final para publicar `v1.3.0`.
