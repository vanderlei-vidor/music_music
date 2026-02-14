# Changelog

Todas as mudanças relevantes deste projeto serão documentadas aqui.

## [1.1.0] - 2026-02-12

### Added
- Tela de boas-vindas personalizada com nome do usuário e resumo da biblioteca.
- Persistência de preferências de boas-vindas (nome e controle de exibição diária).
- Arquivo central de identidade do app (`AppInfo`) para nome/descrição.
- README de produto com stack, arquitetura e fluxo de build.

### Changed
- Fluxo de entrada atualizado: `Splash -> Welcome/Home` conforme regra diária.
- Aba de playlists na Home otimizada para usar estado em memória (sem `FutureBuilder` recorrente no build).
- Metadados de release atualizados (`pubspec` versão `1.1.0+2` e descrição de produto).
- Label Android atualizado para `Music Music`.
- Textos principais alinhados para PT-BR.

### Performance
- Import/scan de músicas otimizado com inserção em lote e transação no SQLite.
- Índices adicionados no banco para favoritos, recentes, mais tocadas e relação de playlist.
- Player com redução de rebuilds globais (seleção de estado mais fina).
- Cache de artwork no player para evitar consultas repetidas em rebuild.

### Fixed
- Ações do drawer da Home que estavam sem navegação.
- Filtro da tela de detalhe de playlist (lista filtrada agora aplicada corretamente).

### Quality
- `flutter analyze` sem issues após as mudanças.
- Testes existentes (`flutter test`) passando.

