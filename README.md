<!-- Autor: Davi de Assis Fabricio -->
# 🐭 Mounator — o rato que adivinha o que você está pensando

Atividade de Fixação e Aprofundamento de **Flutter** (Curso Técnico de Desenvolvimento de Sistemas).
O projeto pedido era o *EcoQuest*; aqui ele foi adaptado para o **Mounator**: um clone do Akinator em que,
no lugar do gênio da lâmpada, quem faz as perguntas é um **rato**.

## Como o jogo funciona

Você pensa em algo (um animal, uma comida, um objeto ou uma profissão) e o rato faz perguntas
("Ele voa?", "É doce?"...). Você responde *Sim / Provavelmente / Não sei / Provavelmente não / Não*.
Quando o rato acha que sabe, ele dá um palpite. Se errar os 3 palpites, **você enganou o rato**.

| Pedido da atividade (EcoQuest) | No Mounator |
|---|---|
| Missão | Desafio contra o rato: uma categoria + dificuldade (quantas perguntas o rato tem) |
| Concluir missão | Terminar uma rodada (o rato acerta ou desiste) |
| Pontos | Pontos da missão; **+50% de bônus** se você enganar o rato |
| Conquistas | Primeiros Passos, Enganador de Ratos, Mestre dos Bichos... |
| Ranking | Jogadores ordenados pelo `score` direto no banco |
| Nível / avatar que evolui | 5 níveis; o rato ganha óculos, chapéu de detetive e coroa |
| Filtros | Por categoria e por status na Home |

## Tecnologias

Flutter · Supabase (Auth + PostgreSQL + RLS) · GoRouter

## Como executar

1. **Supabase**: crie um projeto em <https://supabase.com>.
2. Abra **SQL Editor**, cole o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**
   (cria tabelas, segurança, funções e os dados iniciais; pode rodar de novo para recomeçar do zero).
3. Em **Authentication > Providers > Email**, desative **Confirm email** (assim o cadastro já entra direto na demonstração).
4. Em **Project Settings > API**, copie a **Project URL** e a chave **anon public**.
5. Cole os dois valores em `lib/config/supabase_config.dart` **ou** rode com `--dart-define`:
   ```bash
   flutter create .          # só na primeira vez, para gerar android/ios/web
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://bkktcwfciebkjdatsrqd.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJra3Rjd2ZjaWVia2pkYXRzcnFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NDgxNDEsImV4cCI6MjEwOTUyNDE0MX0.XAdtZYggcKfloZ4Hwiko-_d9i2jaINqdUsQM4fS9ZBI
   ```
   > No Android, o `flutter create .` já cria a pasta `android` com a permissão de internet necessária para builds de debug.

## Estrutura do código (`lib/`)

```
main.dart / app.dart          inicialização do Supabase e MaterialApp.router
config/                       URL e chave do Supabase
router/app_router.dart        todas as rotas (GoRouter) e a proteção por login
models/                       Mission, Achievement, PlayerProfile, Character, Question
game/mounator_engine.dart     o "cérebro" do rato (escolhe perguntas e palpites)
game/player_level.dart        níveis do jogador
services/                     AuthService, MounatorRepository (todas as consultas), erros
screens/                      splash, login, cadastro, home, detalhes, jogo, conquistas, ranking, perfil
widgets/                      componentes reutilizáveis
```

### Widgets personalizados (reutilizáveis, recebem dados por parâmetro)

`MissionCard` · `ProgressCard` · `AchievementBadge` · `RankingTile` · `MouseAvatar` · `SpeechBubble` ·
`MissionStatusBadge` · `DataView` (carrega, trata erro/vazio e recarrega) · `LoadingView` / `EmptyView` / `ErrorView`

### Rotas (GoRouter)

| Rota | Tela | Observação |
|---|---|---|
| `/splash` | Abertura | Decide entre login e home conforme a sessão |
| `/login`, `/register` | Acesso | Só para quem **não** está logado |
| `/home`, `/achievements`, `/ranking`, `/profile` | Telas principais | Dentro de um `ShellRoute` com barra de navegação |
| `/mission/:id` | Detalhes | Recebe a missão por `extra` e o id pela URL |
| `/play/:id` | Rodada do jogo | Recebe a missão por `extra` |

O `redirect` do `GoRouter` manda qualquer visitante sem sessão para `/login`, e o `refreshListenable`
reavalia isso a cada login/logout (`onAuthStateChange`).

## Banco de dados

```
auth.users ──1:1── profiles (nickname, score)
                      │
                      ├──< user_missions >── missions        (status, stumped, points_earned)
                      └──< user_achievements >── achievements
characters, questions  → dados que o rato usa para adivinhar (por categoria)
```

- `user_missions` tem `unique (user_id, mission_id)`: **a mesma missão nunca pontua duas vezes**.
- Cada linha pertence a `auth.uid()`; o app só enxerga os próprios registros (RLS).
- **A pontuação não pode ser manipulada pelo app**: o cliente só tem permissão de leitura, e de escrever o apelido.
  O `score` só muda dentro da função `complete_mission`, que roda no servidor (`security definer`),
  confere o usuário logado, calcula os pontos, evita pontuar duas vezes e libera as conquistas.
- O ranking vem da função `get_ranking`, que ordena os perfis no banco e devolve o top 20 mais a linha do usuário logado.

## Roteiro da demonstração (desafio final)

1. **Cadastro** → entra direto na Home.
2. Veja a **lista de missões** e os filtros.
3. Abra uma missão → **Iniciar desafio** → pense em algo e responda ao rato. Para ver o bônus, pense em algo
   que o rato não conhece (ex.: "Jacaré" em Animais) e responda "Errou" nos palpites.
4. Volte e veja a **pontuação** atualizada na Home.
5. Abra **Conquistas** e **Ranking** (crie uma segunda conta para ver os dois no ranking).
6. **Sair** e entrar de novo: pontos, missões e conquistas continuam lá, porque estão no PostgreSQL.

## Explicação para a apresentação

- **Widgets**: telas só montam a página; o que se repete (cartão de missão, progresso, conquista, linha do ranking)
  virou widget com parâmetros.
- **Rotas**: todas ficam em `app_router.dart`; a missão escolhida vai por parâmetro e o login é verificado no `redirect`.
- **Dados do usuário**: toda tabela de progresso guarda o `user_id` do `auth.users`, e o RLS compara com `auth.uid()`.
- **Motor do rato**: cada resposta multiplica o peso de cada candidato; a próxima pergunta é a que mais divide os candidatos
  ao meio; o rato só chuta quando está confiante (80%) ou quando as perguntas acabam.

## Entrega

- Repositório público no GitHub com este README.
- `.zip` com **somente** a pasta `lib` e o arquivo `pubspec.yaml`.

---
Feito por Davi de Assis Fabricio
