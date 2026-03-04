# Changelog

Todas as mudancas relevantes deste projeto serao documentadas aqui.

## [1.2.0] - 2026-03-04

### Added
- Equalizador avancado com presets padrao e presets custom do usuario (salvar/aplicar/renomear/excluir).
- Export/import de presets custom em JSON direto pela UI do equalizador.
- Perfis de saida por dispositivo (`Fone`, `Bluetooth`, `Carro`) com persistencia por perfil.
- Troca automatica de perfil por rota de audio usando `audio_session` (`devicesStream`).
- Ferramenta de reprocessamento de generos em lote para biblioteca local.
- Modo experimental de processamento iOS do EQ:
  - `Preamp-only`
  - `Tonal synthesis`
  - `True multiband (WIP)`

### Changed
- Visual do equalizador reformulado para padrao premium:
  - sliders verticais por banda
  - curva de resposta animada
  - area de ganho/perda preenchida
  - escala lateral `+12 / 0 / -12 dB`
  - trilha visual de picos (ghost/trailing curve)
- `EqualizerSheet` tornou-se responsiva com scroll e altura maxima para evitar overflow em telas menores.
- Fluxo de genero no player reforcado com fallback por pasta e heuristica textual.

### iOS
- Inicio do caminho de fork local do `just_audio` para evoluir EQ nativo:
  - `dependency_overrides` apontando para `third_party/just_audio`
  - API Dart no player do fork: `darwinSetEqualizer(...)`
  - hook nativo por player no Darwin plugin para receber estado do EQ
- Preamp iOS aplicado com efeito audivel imediato no backend atual (composicao de volume + ganho em dB).
- Bandas no iOS atualmente usando fallback tonal (`Tonal synthesis`) ate fechamento do `True multiband`.

### Performance
- Aplicacao do EQ serializada por backend para evitar condicoes de corrida.
- Persistencia debounce de estado do equalizador mantida para reduzir I/O.

### Fixed
- Correcao de `RenderFlex overflow` na folha do equalizador.
- Correcao de estado condicionado por pasta em navegacao de biblioteca (desacoplamento para fluxo global).

### Quality
- `flutter analyze` sem issues apos as mudancas.
- `flutter test` com testes existentes passando.

## [1.1.0] - 2026-02-12

### Added
- Tela de boas-vindas personalizada com nome do usuario e resumo da biblioteca.
- Persistencia de preferencias de boas-vindas (nome e controle de exibicao diaria).
- Arquivo central de identidade do app (`AppInfo`) para nome/descricao.
- README de produto com stack, arquitetura e fluxo de build.

### Changed
- Fluxo de entrada atualizado: `Splash -> Welcome/Home` conforme regra diaria.
- Aba de playlists na Home otimizada para usar estado em memoria (sem `FutureBuilder` recorrente no build).
- Metadados de release atualizados (`pubspec` versao `1.1.0+2` e descricao de produto).
- Label Android atualizado para `Music Music`.
- Textos principais alinhados para PT-BR.

### Performance
- Import/scan de musicas otimizado com insercao em lote e transacao no SQLite.
- Indices adicionados no banco para favoritos, recentes, mais tocadas e relacao de playlist.
- Player com reducao de rebuilds globais (selecao de estado mais fina).
- Cache de artwork no player para evitar consultas repetidas em rebuild.

### Fixed
- Acoes do drawer da Home que estavam sem navegacao.
- Filtro da tela de detalhe de playlist (lista filtrada agora aplicada corretamente).

### Quality
- `flutter analyze` sem issues apos as mudancas.
- Testes existentes (`flutter test`) passando.

