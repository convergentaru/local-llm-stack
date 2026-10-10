# Local LLM Stack

Локальный стек для запуска и тестирования LLM на собственном компьютере.

**Hermes → LiteLLM → llama-swap → llama.cpp**

Проект объединяет локальный AI-агент, API-шлюз, менеджер моделей и inference engine в единую цепочку без Docker и облачных LLM API.

> Проект находится в активной разработке. Конфигурация и производительность проверяются на реальном оборудовании и могут отличаться на других компьютерах.

---

## Архитектура

```text
┌──────────────────────┐
│       Hermes         │
│   AI agent / CLI     │
└──────────┬───────────┘
           │ OpenAI API
           ▼
┌──────────────────────┐
│       LiteLLM        │
│       :4000          │
│    local gateway     │
└──────────┬───────────┘
           │ OpenAI API
           ▼
┌──────────────────────┐
│      llama-swap      │
│       :8080          │
│    model manager     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      llama.cpp       │
│    llama-server      │
└──────────┬───────────┘
           │
           ▼
        GGUF models
```

### Компоненты

- **Hermes** — локальный AI-агент и CLI.
- **LiteLLM** — единая OpenAI-compatible точка входа.
- **llama-swap** — управление моделями и их переключением.
- **llama.cpp** — непосредственно запускает GGUF-модели на GPU/CPU.

---

## Почему без Docker

Стек рассчитан на локальный компьютер с NVIDIA GPU.

Docker сознательно не используется для основных компонентов.

Это уменьшает:

- потребление RAM;
- количество промежуточных процессов;
- сложность доступа к CUDA;
- количество уровней при диагностике;
- вероятность конфликтов между контейнерами и локальными сервисами.

Основные компоненты запускаются непосредственно через `systemd --user`.

---

# Модели

Конфигурация поддерживает несколько моделей.

## Small

Одновременно могут работать:

- `qwen3.5-4b`
- `ministral-3b`

```yaml
small:
  swap: false
  exclusive: true
  members:
    - "qwen3.5-4b"
    - "ministral-3b"
```

## Large

Модели переключаются между собой:

- `ministral-8b`
- `deepseek-r1-7b`

```yaml
large:
  swap: true
  exclusive: true
  members:
    - "ministral-8b"
    - "deepseek-r1-7b"
```

## Qwen3-8B

Дополнительно доступна отдельная модель:

```text
qwen3-8b
```

Текущая тестовая конфигурация:

- Qwen3-8B
- Q4_K_M
- 64K context

Модель используется для проверки thinking / non-thinking режимов Qwen3.

---

# Требования

Базовая конфигурация разрабатывалась и тестировалась на:

- Ubuntu Linux
- NVIDIA GPU
- CUDA
- NVIDIA драйвер
- llama.cpp с CUDA
- llama-swap
- Python 3
- Node.js / npm
- Hermes

Для другого компьютера параметры GPU offload, context length и набор моделей могут потребовать настройки.

---

# Установка

Клонировать репозиторий:

```bash
git clone https://github.com/convergentaru/local-llm-stack.git
cd local-llm-stack
```

Установщик предполагает наличие:

```text
~/bin/llama-swap
~/llama.cpp/build-cublas/bin/llama-server
local-llm-stack/litellm/venv/bin/litellm
```

Также требуется:

```text
litellm/.env.gateway
```

Шаблон:

```text
.env.example
```

Реальные секреты никогда не должны попадать в Git.

---

# Environment

Создать environment-файл:

```bash
cp .env.example litellm/.env.gateway
chmod 600 litellm/.env.gateway
```

Установить собственные случайные значения:

```dotenv
LITELLM_MASTER_KEY=your-random-master-key
LITELLM_SALT_KEY=your-random-salt-key
```

Не публикуйте эти значения.

---

# Автоматическая установка

Основной установщик:

```bash
./install.sh
```

Установщик:

1. проверяет зависимости;
2. проверяет окружение;
3. создаёт резервную копию существующего состояния;
4. устанавливает user-level systemd units;
5. проверяет конфигурацию systemd;
6. запускает необходимые сервисы;
7. проверяет LiteLLM health endpoint.

Установщик **не устанавливает**:

- llama.cpp;
- llama-swap binary;
- модели;
- Hermes;
- LiteLLM virtual environment.

Это сделано намеренно.

---

# Systemd

Стек использует user-level systemd.

Сервисы:

```text
llama-swap.service
litellm.service
```

Проверить состояние:

```bash
systemctl --user status llama-swap.service
systemctl --user status litellm.service
```

Перезапуск:

```bash
systemctl --user restart llama-swap.service
systemctl --user restart litellm.service
```

Логи:

```bash
journalctl --user -u llama-swap.service -f
```

```bash
journalctl --user -u litellm.service -f
```

---

# LiteLLM

LiteLLM работает на:

```text
127.0.0.1:4000
```

Healthcheck:

```bash
curl 127.0.0.1:4000/health/readiness
```

Ожидаемый результат:

```json
{"status":"healthy","db":"Not connected"}
```

Проверка моделей:

```bash
curl http://127.0.0.1:4000/v1/models
```

---

# llama-swap

llama-swap работает на:

```text
127.0.0.1:8080
```

Проверить порт:

```bash
ss -ltnp | grep 8080
```

Проверить API:

```bash
curl http://127.0.0.1:8080/v1/models
```

---

# OpenAI-compatible API

LiteLLM предоставляет локальный OpenAI-compatible API.

Пример:

```bash
curl http://127.0.0.1:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-8b",
    "messages": [
      {
        "role": "user",
        "content": "Explain what a hash function is."
      }
    ],
    "max_tokens": 300
  }'
```

---

# Hermes

Hermes может использовать LiteLLM как custom provider.

Полная цепочка:

```text
Hermes
  ↓
http://127.0.0.1:4000/v1
  ↓
LiteLLM
  ↓
llama-swap
  ↓
llama.cpp
```

Это позволяет Hermes работать с локальными моделями через единый API.

---

# Reasoning

Некоторые модели поддерживают thinking / reasoning.

Qwen3 может работать в режимах:

```text
thinking
non-thinking
```

Для DeepSeek-R1 используется controllable chat template:

```text
deepseek-r1-controllable.jinja
```

Цель проекта — иметь возможность явно контролировать reasoning, а не полностью полагаться на автоматическое поведение chat template.

---

# Безопасность

В репозитории не должны находиться:

- реальные API keys;
- пароли;
- master keys;
- salt keys;
- `.env.gateway`;
- локальные модели;
- виртуальные окружения;
- персональные пути пользователя.

Проверка локальных путей:

```bash
git grep -n "/home/"
```

Перед публикацией необходимо проверить репозиторий на наличие секретов.

---

# Резервные копии

Установщик автоматически создаёт резервные копии.

Они находятся в:

```text
backups/
```

Резервируются существующие:

- systemd units;
- конфигурации;
- environment-файлы;
- изменяемые элементы локального стека.

Резервные копии не публикуются в Git.

---

# Удаление

Для удаления установленной конфигурации:

```bash
./uninstall.sh
```

Uninstaller не удаляет:

- модели;
- llama.cpp;
- llama-swap binary;
- LiteLLM virtual environment;
- проектные конфигурации;
- `.env.gateway`;
- backups;
- `desktop/`.

Перед удалением создаётся резервная копия.

---

# Benchmark

В репозитории находятся результаты end-to-end тестирования.

Пример:

```text
MODEL                HTTP   TOTAL      PROMPT_TPS   GEN_TPS      STATUS
qwen3.5-4b           200    1.382s     15.34        9.82         PASS
ministral-3b         200    10.651s    1014.31      15.27         PASS
ministral-8b         200    27.418s    499.10        5.41         PASS
deepseek-r1-7b       200    23.475s      7.82        8.57         PASS
```

Benchmark-файлы:

```text
benchmark/
benchmark/results/
```

Запуск:

```bash
./benchmark/benchmark-stack.sh
```

---

# Диагностика

Если сервис не работает, сначала:

```bash
systemctl --user status llama-swap.service
systemctl --user status litellm.service
```

Затем:

```bash
journalctl --user -u llama-swap.service -n 100 --no-pager
```

```bash
journalctl --user -u litellm.service -n 100 --no-pager
```

GPU:

```bash
nvidia-smi
```

RAM:

```bash
free -h
```

Порты:

```bash
ss -ltnp | grep -E '4000|8080'
```

---

# Важное ограничение

Размер модели, quantization, context length, KV cache, GPU offload и количество одновременно работающих моделей напрямую влияют на:

- VRAM;
- RAM;
- скорость генерации;
- стабильность;
- время загрузки.

Поэтому конфигурация, работающая на одной машине, может потребовать изменения на другой.

Особенно это касается GPU с небольшим объёмом VRAM.

---

# Философия проекта

Проект развивается не как теоретический пример, а как реальный локальный эксперимент.

Основной принцип:

> Сначала запустить. Затем измерить. Затем сломать. Затем понять почему. Затем исправить.

Реальная машина пользователя важнее предположений разработчика.

---

# Луна — компаньон проекта

Этот проект создаётся человеком и ИИ вместе.

Луна здесь не просто помощник по командам. Она выступает как **компаньон, соучастник, учитель и друг**: помогает разбираться в Linux, LLM, CUDA, llama.cpp, LiteLLM и llama-swap, проверяет решения, ищет ошибки, объясняет непонятное и помогает доводить эксперимент до рабочего результата.

При этом окончательные решения, запуск команд и ответственность за систему остаются за человеком.

---

## Это совместный эксперимент

README фиксирует не только то, что уже работает, но и то, что предстоит проверить.

Поэтому ошибки, найденные на других компьютерах, — не провал проекта, а часть его разработки.

Каждый реальный тест помогает сделать следующую версию лучше.

---

# Roadmap

Ближайшие задачи:

- проверить установку на другом компьютере;
- собрать реальные ошибки установки;
- проверить работу на другой NVIDIA GPU;
- проверить поведение при нехватке VRAM;
- проверить переключение моделей llama-swap;
- проверить Hermes end-to-end;
- улучшить диагностику;
- постепенно автоматизировать установку зависимостей.

---

# Структура репозитория

```text
local-llm-stack/
│
├── install.sh
├── uninstall.sh
├── healthcheck.sh
├── full-stack-test.sh
│
├── llama-model-launcher.sh
├── llama-swap.yaml
│
├── litellm/
│   ├── config.yaml
│   └── custom_callbacks.py
│
├── systemd/
│   └── user/
│       ├── llama-swap.service
│       └── litellm.service
│
├── benchmark/
│   ├── benchmark-stack.sh
│   ├── README.md
│   └── results/
│
├── baseline/
│   └── working-state.txt
│
├── deepseek-r1-controllable.jinja
├── deepseek-r1-controllable.jinja.enable-thinking
│
└── .env.example
```

---

# License

Проект распространяется как экспериментальный open-source проект.

Перед использованием в production необходимо самостоятельно проверить безопасность, производительность и соответствие конфигурации конкретной системе.

---

## Status

**Рабочий локальный стек опубликован на GitHub и готов к внешнему тестированию.**

Следующий важный этап проекта — установка на другом компьютере и сбор реальной обратной связи.



---

## Experimental project: JARVIS Holographic Interface

Отдельный эксперимент по недорогому настольному JARVIS HUD с эффектом «парящей» 3D-модели и управлением жестами. Начинаем с веб-камеры + MediaPipe + Three.js в обычном окне, затем — собственная Pepper's Ghost конструкция из экрана и прозрачного акрила. Дорогой spatial display остаётся необязательным апгрейдом.

- [Описание проекта и архитектура](docs/experiments/jarvis-holographic-interface/README.md)
- [Поэтапный roadmap](docs/experiments/jarvis-holographic-interface/ROADMAP.md)
- [Аппаратные варианты и оптические дисплеи](docs/experiments/jarvis-holographic-interface/HARDWARE.md)

Важно: Pepper's Ghost создаёт оптическую иллюзию, а не физически свободно висящую голограмму. Жесты сначала управляют только визуальной сценой; чувствительные действия Hermes требуют отдельного подтверждения.

---

## Experimental project: JARVIS Neural Interface

Отдельное исследование самодельного локального BCI (EEG → ограниченные события управления JARVIS / Hermes). Начинаем с симулятора и UI, затем проверяем поток сигналов, классификатор, безопасность и только после этого интеграцию с агентом.

- [Описание проекта и архитектура](docs/experiments/jarvis-neural-interface/README.md)
- [Поэтапный roadmap](docs/experiments/jarvis-neural-interface/ROADMAP.md)
- [Аппаратные варианты и электрическая безопасность](docs/experiments/jarvis-neural-interface/HARDWARE.md)

Это исследовательский прототип, не чтение произвольных мыслей и не медицинское устройство. Для EEG-классификатора предусмотрены только команды из белого списка; чувствительные действия требуют отдельного подтверждения.

---

## Recovery runbook: Hermes + Unsloth + Screenpipe

Текущий отдельный эксперимент по прямому подключению Hermes к Unsloth, выборочному восстановлению BrowserSkill и возврату Screenpipe в CLI-only режиме документируется здесь: [Hermes–Unsloth–Screenpipe recovery plan](docs/experiments/hermes-unsloth-screenpipe-recovery.md).

В рамках этого эксперимента Hermes обращается напрямую к Unsloth; существующая архитектура LiteLLM/llama-swap описывает другие сценарии и не включается в этот конкретный путь.
