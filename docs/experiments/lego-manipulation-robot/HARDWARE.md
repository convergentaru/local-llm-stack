# Hardware research — LEGO Manipulation Robot

## 1. LEGO Education: color sorting

LEGO Education сохраняет официальный учебный проект [Make a System That Sorts Colors](https://education.lego.com/en-us/lessons/ev3-dep/make-a-system-that-sorts-colors/). В нём требуется определить минимум три цвета LEGO elements и сортировать их по отдельным местам; пример использует Color Sensor, моторы и Ultrasonic Sensor.

Это полезный baseline для сенсорики и сортировки. Это не универсальная рука для автоматической идентификации произвольных деталей и сборки.

LEGO Education также сохраняет материалы EV3 с инструкциями для Color Sorter и Robot Arm: [EV3 building instructions](https://education.lego.com/en-us/product-resources/mindstorms-ev3/downloads/building-instructions/).

**Важно для покупки:** LEGO Education объявила о выводе SPIKE Essential/Prime из портфеля; приложение заявлено поддерживаемым до 30 июня 2031. Если набора уже нет, перед покупкой стоит сравнить стоимость/доступность запчастей и альтернативы. См. [официальное обновление SPIKE](https://www.education.lego.com/en-us/spike-update-2026/).

## 2. SO-ARM101 / SO-ARM100 — рекомендуемый открытый манипулятор для pick-and-place

Источник: [TheRobotStudio/SO-ARM100](https://github.com/TheRobotStudio/SO-ARM100).

Что это:
- 3D-печатаемая рука с открытыми механическими файлами;
- документация для SO-101 и устаревающего SO-100;
- шестимоторный follower arm со gripper в конфигурации SO-101;
- интеграция с [Hugging Face LeRobot](https://github.com/huggingface/lerobot);
- возможность телеуправления leader arm и сбора демонстраций для роботического обучения.

Repository license: Apache-2.0. Проверить актуальный BOM, STL, двигатели, кабели, питание и лицензии компонентов перед изготовлением.

Официальная инструкция по сборке и калибровке: [LeRobot SO-101](https://huggingface.co/docs/lerobot/so101?assembly=Leader).

**Ограничение:** обычный gripper достаточен для множества pick-and-place задач, но не гарантирует точное поворачивание очень мелких деталей или соединение LEGO studs. Для начала использовать хорошо доступные одинаковые детали и фиксированные лотки.

## 3. LEAP Hand — исследовательская многопальцевая рука

Источники:
- [LEAP Hand V1 API](https://github.com/leap-hand/LEAP_Hand_API)
- [LEAP Hand V2 API](https://github.com/leap-hand/LEAP_Hand_V2_API)
- [LEAP Hand V2 Advanced API](https://github.com/leap-hand/LEAP_Hand_V2_Adv_API)

Это значительно более сложный механизм для dexterous manipulation; V2 Advanced описывается upstream как 17-DoF hybrid rigid-soft hand.

Важная лицензия: README API LEAP Hand V1 указывает MIT для software и CC BY-NC-SA для CAD. Это **не означает, что весь аппаратный дизайн можно свободно применять коммерчески**. Перед производным распространением или коммерческим применением следует проверить актуальные CAD/hardware terms для конкретной версии.

Рекомендация: не начинать с LEAP Hand. Сначала доказать, что простой manipulator и gripper выполняют конкретную задачу.

## 4. Perception: цвет, форма, геометрия и part ID — разные задачи

- Цветовой датчик хорошо подходит для контролируемого условия и ограниченного набора цветов.
- RGB-камера даёт изображение, позволяет детектировать контуры/ориентацию и дополнять цвет.
- Распознавание LEGO part ID требует визуальной базы, подходящих примеров и оценки уверенности; цвет сам по себе не идентифицирует деталь.
- BOM / LDraw reference помогает задавать ожидаемый inventory и assembly steps, но сама по себе не решает camera-to-world calibration.

Для первой версии применить фиксированное освещение, нескользящую матовую подложку и известную позицию захвата.

## 5. Захват и сборка

Pick-and-place:
- параллельные губки с небольшими мягкими накладками;
- ограниченная скорость и рабочая зона;
- known source/bin pose;
- повторная локализация и проверка результата камерой.

Snap-fit assembly:
- нужна более точная оценка ориентации;
- основа должна удерживаться fixture/jig;
- требуется контролируемый контакт/усилие и проверка посадки;
- не использовать свободное «нажатие на глаз» от LLM;
- тестировать на отдельных деталях и измерять повреждения.

Пять пальцев не являются автоматически лучшим выбором. Хороший gripper плюс механическая оснастка часто проще в первом прототипе.

## 6. Safety

- Аппаратный emergency stop или способ немедленно снять питание приводов.
- Рабочая зона без пальцев человека во время движения.
- Консервативные скорость, acceleration, torque/current limits.
- Camera loss, unknown object, stale command и communication error → stop/no-op.
- Контроллер проверяет границы позы и инструмента; Hermes не может менять safety limits.
- Сначала simulation/dry-run, затем движения на столе с низкой энергией.

## Основные источники

1. [LEGO Education EV3 Color Sorter](https://education.lego.com/en-us/lessons/ev3-dep/make-a-system-that-sorts-colors/)
2. [LEGO EV3 Building Instructions](https://education.lego.com/en-us/product-resources/mindstorms-ev3/downloads/building-instructions/)
3. [LEGO SPIKE 2026 portfolio update](https://www.education.lego.com/en-us/spike-update-2026/)
4. [TheRobotStudio/SO-ARM100](https://github.com/TheRobotStudio/SO-ARM100)
5. [Hugging Face LeRobot SO-101 assembly](https://huggingface.co/docs/lerobot/so101?assembly=Leader)
6. [LEAP Hand API](https://github.com/leap-hand/LEAP_Hand_API)
