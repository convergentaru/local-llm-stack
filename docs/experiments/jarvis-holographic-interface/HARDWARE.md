# Hardware & options — JARVIS Holographic Interface

## Рекомендация

Начать с самого дешёвого пути: имеющийся компьютер/монитор или смартфон, веб-камера, прозрачный акрил и затемняемый корпус. Сначала отладить программу в обычном браузерном окне; акрил и оптика не должны мешать поиску ошибок в распознавании жестов.

## Вариант A — Pepper's Ghost DIY (первый физический прототип)

### Что нужно

- Экран ноутбука, отдельный монитор или смартфон.
- Прозрачный акрил/ПЭТ подходящей геометрии (для первого опыта можно взять готовую небольшую четырёхстороннюю пирамиду; размер согласовать с экраном).
- Простой чёрный корпус, рамка или крепление.
- Веб-камера, направленная на область взаимодействия.
- Ubuntu-компьютер, Three.js и локальное приложение MediaPipe.

### Принцип

Экран отображает четыре синхронизированные перспективы. Каждая отражается от грани прозрачной пирамиды, создавая впечатление объекта внутри объёма. Это оптическая иллюзия отражения.

Плюсы: недорогой вход, корпус можно изготовить самостоятельно, внешний вид меняется программно.

Минусы: ниже яркость, важны тёмный фон и контролируемое освещение, углы и масштаб требуют калибровки.

Примеры:
- [ojasra0kulkarni/hologram-system](https://github.com/ojasra0kulkarni/hologram-system) — reference implementation webcam → MediaPipe → gesture engine → WebSocket → phone/four-view output. README помечает инструкции настройки как Windows; перед использованием на Ubuntu потребуется адаптация и проверка.
- [dylankainth/starkhacks — Pony Stark](https://github.com/dylankainth/starkhacks) — iPhone ARKit/Vision распознаёт жесты и передаёт события ноутбуку.
- [MIT Cyber Fishing prototype](https://fab.cba.mit.edu/classes/863.25/people/ShengtaoShen/final/final.html) — пример акриловой оптической конструкции.

## Вариант B — обычный монитор + веб-камера (первый программный этап)

Начать с 3D-сцены на обычном мониторе. Жестами управлять объектом без оптического корпуса.

Плюсы: не нужны покупки; можно сразу тестировать MediaPipe, gesture engine и UI; проще измерять FPS и latency.

Минус: нет эффекта «объект парит в воздухе» до сборки оптики.

**Рекомендация:** первый спринт должен использовать этот вариант.

## Вариант C — специализированный hand-tracking сенсор

Ultraleap использует ИК-камеры и подсветку и предназначен для точного отслеживания рук. Документация описывает API LeapC и интеграции для Unity/Unreal, однако требования выбранной версии ПО могут указывать Windows. Не покупать сенсор до проверки возможности запуска требуемого SDK на Ubuntu.

- [Ultraleap Hand Tracking Overview](https://docs.ultraleap.com/hand-tracking/index.html)
- [Ultraleap Getting Started](https://docs.ultraleap.com/hand-tracking/getting-started.html)

## Вариант D — Light-field / spatial display

Специализированный дисплей создаёт объёмное впечатление из нескольких направлений просмотра, без нашей отражающей пирамиды. Это дорогой и необязательный путь.

- [Looking Glass Go — официальный продукт](https://checkout.lookingglassfactory.com/products/looking-glass-go): производитель указывает 6-дюймовый light-field дисплей, до 100 видов, viewing cone 58° и поддержку iPhone/Mac/PC. Страница динамически показывает цену и доступность; перепроверить перед покупкой.
- [Looking Glass WebXR](https://github.com/Looking-Glass/looking-glass-webxr): интеграция с Three.js и Babylon.js через WebXR/polyfill; требует устройства и Looking Glass Bridge.
- [Looking Glass displays](https://checkout.lookingglassfactory.com/collections/displays): модели и цена зависят от размера и конфигурации.

Не покупать spatial display до того, как DIY-клиент заработает и будет ясно, чего ему не хватает.

## Gesture tracking: программные варианты

### MediaPipe Hand Landmarker

Рекомендуемый старт для обычной RGB-веб-камеры:

- [Официальная инструкция Python](https://developers.google.com/edge/mediapipe/solutions/vision/hand_landmarker/python)
- работает с кадрами изображения и возвращает landmarks кисти;
- позволяет начать с Python acquisition/gesture engine;
- нужно проверить версии Python и пакетные колёса для выбранной Ubuntu. Не переносить Windows-инструкции без изменений.

### OpenCV

Использовать для захвата кадра, проверки экспозиции/FPS и отладочного оверлея. Для landmarks предпочтительнее использовать MediaPipe, чем разрабатывать распознавание руки с нуля.

### Протокол событий

По локальному WebSocket передавать типизированные события, не видеокадры. Пример концепции:

    type: gesture
    name: PINCH_DRAG
    confidence: 0.91
    timestamp_ms: 123456789
    sequence: 42

Это иллюстрация, а не уже утверждённый API. Нужны строгая валидация, порог уверенности, cooldown, обработка устаревших событий и запрет произвольных команд, URL или скриптов.

## Требования к прототипу

- [ ] Ubuntu поддерживает захват камеры и выбранную версию MediaPipe.
- [ ] Hand tracking выполняется локально.
- [ ] Dev-панель показывает landmarks, gesture, confidence, FPS и latency.
- [ ] Потеря/плохое качество tracking приводит к no-op.
- [ ] Настройки калибровки вынесены в конфигурацию.
- [ ] Видеопоток не публикуется и не сохраняется по умолчанию.
- [ ] Сначала жесты управляют только 3D-объектом, не опасными инструментами Hermes.

## Источники

1. [MediaPipe Hand Landmarker for Python](https://developers.google.com/edge/mediapipe/solutions/vision/hand_landmarker/python)
2. [Pepper's Ghost hand-controlled example](https://github.com/ojasra0kulkarni/hologram-system)
3. [Pony Stark DIY hologram](https://github.com/dylankainth/starkhacks)
4. [Ultraleap Hand Tracking](https://docs.ultraleap.com/hand-tracking/index.html)
5. [Looking Glass Go](https://checkout.lookingglassfactory.com/products/looking-glass-go)
6. [Looking Glass WebXR](https://github.com/Looking-Glass/looking-glass-webxr)
