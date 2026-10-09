# O Códice dos Ancestrais

![Logo Inicial do jogo](logo/Logo%20incial.png)

Puzzle-RPG medieval tecnológico onde o *Caos Digital* espalhou os segredos do **Códice dos Ancestrais**. Escolha sua facção, navegue por ilhas, templos e castelos, resolva puzzles de tecnologia e restaure o equilíbrio do reino de Eldoria.

---

## 📜 Sobre o Projeto

A memorização de termos técnicos fundamentais, ferramentas, metodologias e sintaxes costuma ser maçante através de decoreba tradicional. **Códice dos Ancestrais** utiliza mecânicas interativas reformuladas para o universo de fantasia medieval tecnológica para acelerar o letramento digital de forma imersiva e engajadora.

### High Concept
Um apagão cibernético (*Caos Digital*) misturou referências, ícones, ferramentas e conceitos de engenharia de software na nuvem global e no reino de Eldoria. O jogador assume o papel de um membro da **Ordem dos Arquitetos** com o objetivo de reconstruir o conhecimento cósmico antes que o tempo esgote.

---

## 🏴‍☠️ Facções Disponíveis

No início da jornada, o jogador escolhe uma entre três facções jogáveis, moldando sua perspectiva, linguagem e progressão na história:
1. **Piratas:** Navegam por mares e ilhas remotas, desbravando rotas alternativas.
2. **Eruditos:** Guardiões do saber, focados no estudo profundo dos artefatos e runas antigas.
3. **Mercenários:** Especialistas em missões táticas e resoluções práticas em fortalezas e castelos.

---

## 🧩 Mecânicas e Tipos de Puzzles

Para diversificar o gameplay além do tradicional jogo da memória e estimular diferentes raciocínios lógicos, o jogo conta com diversos tipos de desafios:

* **Memory Stack (Associação por Pares):** Um tabuleiro estilo jogo da memória onde o jogador conecta o **Conceito/Ferramenta** (ex: *Docker*, *Git Commit*, *Variável Boolean*, *Chave Primária*) à sua **Definição ou Ícone Correto**.
* **Reparo de Conexões (Circuitos / Pipes):** Conecte cabos de energia mágica ou tubulações em um painel tecnológico para restaurar defesas de castelos, simulando fluxos de código ou estruturas condicionais (`if/else`).
* **Decodificação de Runas (Lógica Booleana):** Resolva portas trancadas aplicando operações lógicas (`AND`, `OR`, `NOT`) ou completando sequências de sintaxe correta.
* **Torre de Classificação (Algoritmos e Pilhas):** Organize artefatos e pergaminhos seguindo lógicas computacionais, como ordem de prioridade de processos, pilhas (*stacks*) ou filas (*queues*).
* **Labirinto de Rotas (Redes e Roteamento):** Guie mensageiros ou navios pelo mapa configurando portões mágicos e caminhos de menor custo, simulando pacotes de dados e regras de firewall.

---

## 🚀 Próximos Passos (Roadmap)
- [x] Definição oficial da stack tecnológica (Godot Engine).
- [x] Prototipagem do tabuleiro de associação de cartas (*Memory Stack*).
- [x] Implementação do sistema de escolha de facções.
- [x] Desenvolvimento dos mini-puzzles de memória, circuitos e lógica rúnica.
- [x] Integração do fluxo de cenas, configurações e mapa de Eldoria.

---

## Finalidade
Desenvolvido como projeto pelo Senai Félix Guisard para a matéria de DevOps:

## Docente

*Marcello Benevides*

## Discentes

- *Eric Fabiano*
- *Carlos Eduardo*
- *Ana Carolina*
- *Luiz Gustavo*

## Executar e validar

Abra o projeto no Godot 4.7 e execute `main.tscn` (F6/F5). O fluxo de início leva ao
menu; novos jogos solicitam facção, e jogos salvos podem ser continuados. Os seletores
individuais de fases para desenvolvimento estão em `debug/`; no jogo, as fases são
acessadas pelos territórios do mapa de Eldoria.

Validações headless disponíveis:

```text
godot --headless -s res://tests/localization_validator.gd
godot --headless -s res://tests/test_memory_board_logic.gd
godot --headless -s res://tests/test_circuit_logic.gd
godot --headless -s res://tests/test_rune_logic.gd
godot --headless -s res://tests/smoke_test.gd
```

## Estrutura do projeto

- `autoload/`: localização, salvamento, estado do jogo, áudio e transições de cena.
- `core/`: recursos compartilhados e componentes de base.
- `data/`: facções, conceitos, fases, territórios e catálogo de assets.
- `features/`: tabuleiro da memória, circuitos e lógica rúnica.
- `ui/`: controles reutilizáveis, menus, configurações, mapa e launcher de puzzles.
- `debug/`: seletores de fases independentes, somente para desenvolvimento.
- `localization/`: traduções `en.json` e `pt_BR.json`.
- `docs/`: contratos públicos e lista de assets.
- `tests/`: testes de lógica, localização e referências dos recursos/cenas.

## Adicionar conteúdo

### Idioma

1. Crie `localization/xx.json` contendo as mesmas chaves e placeholders das traduções existentes.
2. Registre `xx` em `Localization.SUPPORTED_LOCALES` e inclua seu nome nativo.
3. Execute o validador de localização acima e revise os textos em todas as telas.

### Conceito, puzzle ou território

- Para um conceito, crie um `ConceptData` em `data/concepts/`, adicione nome, definição
  e dica em ambos os idiomas e referencie o id numa fase de memória.
- Para um puzzle, crie o recurso de fase na pasta do mecanismo correspondente,
  traduza título/introdução/dicas e associe-o a uma entrada de território.
- Para um território, crie `TerritoryData` em `data/territories/`, use id único,
  posição normalizada, nomes/descrições traduzidos e requisitos de desbloqueio válidos.
  Execute `tests/smoke_test.gd` depois de atualizar as referências.

## Entrega de arte e áudio

Os slots, tamanhos recomendados, formatos e fallbacks estão em `docs/ASSET_SLOTS.md`.
Os assets podem ser ligados pelo `data/asset_catalog.tres`, recursos de facção/território
ou exports das cenas de puzzle. Preserve os fallbacks procedurais e silenciosos até a
validação de cada substituição em tela touch, áreas seguras e proporção portrait.