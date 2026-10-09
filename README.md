# O Códice dos Ancestrais (Codex of the Ancients)

![Logo Inicial do jogo](logo/capa%20-%20jogo.png)

Puzzle-RPG medieval tecnológico onde o *Caos Digital* espalhou os segredos do **Códice dos Ancestrais**. Escolha sua facção, navegue pelo mapa de Eldoria, resolva enigmas de computação e restaure o equilíbrio do reino.

Desenvolvido em **Godot Engine 4.7** (Mobile / Desktop) com suporte a touchscreen, arquitetura baseada em dados (`.tres`), testes automatizados headless e suporte nativo a múltiplos idiomas (Inglês e Português do Brasil).

---

## 📜 Sobre o Projeto

A memorização de termos técnicos fundamentais, ferramentas, metodologias e sintaxes costuma ser maçante através de decoreba tradicional. **Códice dos Ancestrais** utiliza mecânicas interativas reformuladas para o universo de fantasia medieval tecnológica para acelerar o letramento digital de forma imersiva e engajadora.

### High Concept
Um apagão cibernético (*Caos Digital*) misturou referências, ícones, ferramentas e conceitos de engenharia de software na nuvem global e no reino de Eldoria. O jogador assume o papel de um membro da **Ordem dos Arquitetos** com o objetivo de reconstruir o conhecimento cósmico antes que o tempo esgote.

---

## 🏴‍☠️ Facções Disponíveis

1. **Piratas:** Navegam por mares e ilhas remotas, desbravando rotas alternativas (+2 jogadas de tolerância no Memory Board).
2. **Eruditos:** Guardiões do saber, focados no estudo profundo de artefatos e runas (25% de desconto no custo de dicas).
3. **Mercenários:** Especialistas em missões táticas e fortalezas (+10 segundos extras em enigmas cronometrados).

---

## 🧩 Mecânicas e Tipos de Puzzles

* **Memory Board (Associação por Pares):** Conecte conceitos de engenharia de software (Docker, Git, Kubernetes, SQL, CI/CD, etc.) às suas definições corretas.
* **Circuito Lógico (Reparo de Conexões):** Gire condutores e conexões para guiar o sinal de fontes (Source) até receptores (Target), simulando pipelines e fluxo de dados.
* **Runas Lógicas (Portas Booleanas):** Alterne sinais e posicione portas lógicas (`AND`, `OR`, `NOT`) ou complete tabelas verdade para abrir portais trancados.

---

## 📁 Estrutura de Pastas

```
O-Codice-dos-Ancestrais/
├── autoload/              # Singletons globais do Godot
│   ├── event_bus.gd       # Hub de sinais desacoplado
│   ├── localization.gd    # Gerenciador de traduções em tempo real
│   ├── save_system.gd     # Persistência atômica e recuperação de save
│   ├── game_manager.gd    # Estado do jogo, facção, estrelas e progresso
│   ├── scene_manager.gd   # Transições de cena, fade overlay e histórico
│   └── audio_manager.gd   # Sistema de áudio com crossfade e segurança de nulos
├── core/                  # Classes de recursos e componentes base
│   ├── asset_catalog.gd   # Registro central de slots de assets
│   ├── faction_data.gd    # Definição de facções
│   ├── territory_data.gd  # Definição de regiões do mapa
│   └── puzzle_result.gd   # Dados de conclusão de enigma
├── data/                  # Recursos (.tres) data-driven
│   ├── concepts/          # 16 conceitos técnicos do Memory Board
│   ├── factions/          # Recursos das facções jogáveis
│   ├── territories/       # 6 territórios do mapa mundi
│   └── puzzles/           # Níveis (.tres) para memory, circuit e runes
├── features/              # Módulos isolados de gameplay
│   ├── circuit_puzzle/    # Lógica, tiles e visualização de circuitos
│   ├── memory_board/      # Lógica e cartas do tabuleiro de memória
│   └── rune_logic/        # Avaliador booleano, tabela verdade e visualização
├── ui/                    # Telas e componentes visuais
│   ├── common/            # ConfirmDialog, ToastNotification, LanguageToggle
│   ├── faction_select/    # Tela de seleção de facção
│   ├── main_menu/         # Menu principal com rotas e novo jogo
│   ├── settings/          # Configurações de idioma, áudio, haptics e save
│   └── world_map/         # Mapa mundi com navegação e seleção de níveis
├── localization/          # Fontes de tradução (en.json, pt_BR.json)
├── tests/                 # Testes unitários e suite headless
└── docs/                  # Documentação de contratos e slots de assets
```

---

## 🎮 Como Executar

### No Godot Editor:
1. Abra o **Godot 4.7+**.
2. Importe o arquivo `project.godot`.
3. Pressione `F5` ou o botão de Play para iniciar a partir de `main.tscn`.

### Linha de Comando (Headless Tests):
```bash
# Executar testes lógicos
godot --headless -s res://tests/test_logic.gd --quit

# Validar integridade e paridade de idiomas
godot --headless -s res://tests/localization_validator.gd --quit

# Executar smoke test completo de cenas e recursos
godot --headless res://tests/smoke_test.tscn
```

---

## 🌐 Como Adicionar um Novo Idioma

1. Crie o arquivo `localization/<locale>.json` (ex: `es.json` para Espanhol).
2. Copie a estrutura de chaves de `localization/en.json` e traduza os valores, preservando todos os tokens `{placeholder}` idênticos.
3. Registre o novo idioma em `autoload/localization.gd`:
   - Adicione o código à constante `SUPPORTED_LOCALES`.
   - Adicione o nome no dicionário `_LOCALE_NAMES`.
4. Execute o validador para garantir 100% de conformidade:
   ```bash
   godot --headless -s res://tests/localization_validator.gd --quit
   ```

---

## ➕ Como Adicionar Novos Conteúdos

### Novo Conceito (Memory Board):
1. Crie um arquivo `data/concepts/<nome>.tres` usando a classe `ConceptData`.
2. Configure `id`, `name_key`, `definition_key`, `hint_key` e associe a textura em `placeholder_icon`.
3. Adicione as chaves correspondentes em `localization/en.json` e `localization/pt_BR.json`.

### Novo Nível de Enigma:
1. Crie o recurso `.tres` na pasta respectiva (`data/puzzles/memory/`, `data/puzzles/circuit/` ou `data/puzzles/runes/`).
2. Adicione o ID do puzzle à lista `puzzle_ids` do território desejado em `data/territories/territory_XX.tres`.

### Novo Território:
1. Crie `data/territories/territory_XX.tres` usando a classe `TerritoryData`.
2. Defina `id`, `name_key`, `description_key`, `map_position` (normalizado 0..1), `required_stars` e `puzzle_ids`.
3. Adicione o caminho do novo território na lista `TERRITORY_PATHS` em `ui/world_map/world_map.gd`.

---

## 🎨 Fluxo de Entrega de Assets (Art & Audio Handoff)

1. Consulte [`docs/ASSET_SLOTS.md`](docs/ASSET_SLOTS.md) para a lista completa de slots de textura e áudio, dimensões recomendadas e formatos (PNG, OGG, WAV).
2. Substitua os assets diretamente nas propriedades `@export` do catálogo `data/asset_catalog.tres` ou dos recursos específicos em `data/`.
3. O código utiliza fallbacks procedurais caso um slot seja `null`, garantindo que o jogo permaneça funcional durante a produção visual.

---

## 👥 Equipe e Finalidade

Projeto desenvolvido no SENAI Félix Guisard para a unidade curricular de DevOps.

### Docente
* **Marcello Benevides**

### Discentes
* **Eric Fabiano**
* **Carlos Eduardo**
* **Ana Carolina**
* **Luiz Gustavo**