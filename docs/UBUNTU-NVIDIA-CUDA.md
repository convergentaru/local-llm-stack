# Ubuntu + NVIDIA + CUDA + llama.cpp

Инструкция для подготовки чистой Ubuntu к запуску Local LLM Stack.

Цепочка:

Ubuntu → NVIDIA Driver → CUDA Toolkit → llama.cpp → Local LLM Stack

## 1. Обновление Ubuntu

```bash
sudo apt update
sudo apt upgrade -y
```

После крупных обновлений:

```bash
sudo reboot
```

## 2. Проверка NVIDIA GPU

```bash
lspci | grep -i nvidia
```

## 3. Установка NVIDIA Driver

Посмотреть рекомендуемый драйвер:

```bash
ubuntu-drivers devices
```

Установить рекомендуемый драйвер:

```bash
sudo ubuntu-drivers install
```

Перезагрузить:

```bash
sudo reboot
```

Проверить:

```bash
nvidia-smi
```

Если `nvidia-smi` не работает, дальше не переходить — сначала исправить драйвер.

## 4. Установка CUDA Toolkit

Для Ubuntu 26.04 используется официальный репозиторий NVIDIA:

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2604/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit
```

Проверить:

```bash
nvcc --version
```

И:

```bash
which nvcc
```

## 5. Инструменты сборки

```bash
sudo apt install -y build-essential cmake git pkg-config
```

Проверить:

```bash
cmake --version
git --version
```

## 6. llama.cpp

Если llama.cpp ещё не установлен:

```bash
cd ~
git clone https://github.com/ggml-org/llama.cpp.git
cd ~/llama.cpp
```

Если уже установлен:

```bash
cd ~/llama.cpp
git pull
```

## 7. CUDA Architecture

Для NVIDIA RTX 3060 используется:

```text
86
```

Поэтому сборка выполняется с:

```text
CMAKE_CUDA_ARCHITECTURES=86
```

Для другой NVIDIA GPU это значение может отличаться.

## 8. Сборка llama.cpp с CUDA

```bash
cd ~/llama.cpp

cmake -B build-cublas \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_FORCE_CUBLAS=ON \
  -DCMAKE_CUDA_ARCHITECTURES=86
```

Сборка:

```bash
cmake --build build-cublas --config Release -j$(nproc)
```

Проверка:

```bash
~/llama.cpp/build-cublas/bin/llama-server --version
```

## 9. Проверка GPU во время работы модели

В отдельном терминале:

```bash
watch -n 1 nvidia-smi
```

При загрузке модели должно быть видно увеличение использования VRAM.

Остановить:

```text
Ctrl+C
```

## 10. Что влияет на VRAM

Потребление VRAM зависит не только от размера GGUF-файла.

На него влияют:

- размер модели;
- quantization;
- context length;
- KV cache;
- тип KV cache;
- количество слотов;
- GPU offload;
- Flash Attention;
- количество одновременно работающих моделей.

Поэтому размер модели на диске нельзя напрямую считать требуемым объёмом VRAM.

## 11. Что не требуется

Для этого проекта не требуется устанавливать:

- Docker;
- NVIDIA `.run` installer;
- cuDNN;
- PyTorch;
- TensorFlow;
- отдельный Python CUDA runtime.

## 12. NVIDIA `.run`

Для Ubuntu предпочтительно использовать пакетный менеджер и официальный NVIDIA repository.

Не следует без необходимости использовать NVIDIA `.run` installer.

Это упрощает обновление, удаление и диагностику драйвера.

## 13. Минимальная проверка

Перед переходом к Local LLM Stack должны работать:

```bash
nvidia-smi
```

```bash
nvcc --version
```

```bash
~/llama.cpp/build-cublas/bin/llama-server --version
```

Также должны существовать:

```text
~/llama.cpp/build-cublas/bin/llama-server
~/bin/llama-swap
~/local-llm-stack/litellm/.env.gateway
```

## 14. Переход к Local LLM Stack

После успешной подготовки:

```bash
cd ~/local-llm-stack
./install.sh
```

Установщик Local LLM Stack намеренно не устанавливает NVIDIA Driver, CUDA Toolkit и llama.cpp.

Архитектура подготовки:

```text
Ubuntu
   ↓
NVIDIA Driver
   ↓
nvidia-smi
   ↓
CUDA Toolkit
   ↓
nvcc
   ↓
llama.cpp CUDA build
   ↓
llama-swap
   ↓
LiteLLM
   ↓
Hermes
```

## 15. Диагностика

NVIDIA:

```bash
nvidia-smi
```

CUDA compiler:

```bash
which nvcc
```

```bash
nvcc --version
```

CUDA directories:

```bash
ls -ld /usr/local/cuda*
```

Установленные CUDA packages:

```bash
dpkg -l | grep -E 'cuda-toolkit|cuda-compiler'
```

llama.cpp:

```bash
~/llama.cpp/build-cublas/bin/llama-server --version
```

Драйвер:

```bash
ubuntu-drivers devices
```

## 16. Для других GPU

Значение:

```text
86
```

соответствует RTX 3060.

Для другой видеокарты необходимо определить её Compute Capability и при необходимости изменить:

```text
CMAKE_CUDA_ARCHITECTURES
```

Не следует автоматически использовать `86` на другой NVIDIA GPU.

## 17. Принцип диагностики

Проверять стек последовательно:

```text
GPU
 ↓
NVIDIA Driver
 ↓
nvidia-smi
 ↓
CUDA Toolkit
 ↓
nvcc
 ↓
llama.cpp CUDA build
 ↓
llama-server
 ↓
llama-swap
 ↓
LiteLLM
 ↓
Hermes
```

Если один слой не работает, следующий пока не настраиваем.

Это значительно упрощает поиск ошибок.

---

## Статус

Этот документ является отдельной инструкцией по подготовке новой Ubuntu-машины перед установкой Local LLM Stack.

Он намеренно хранится отдельно от основного README, чтобы документацию по Ubuntu, NVIDIA и CUDA можно было развивать независимо.
