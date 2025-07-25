# Аналитика для гейминг студии

## Описание проекта

Этот аналитический проект направлен на изучение поведения игроков в онлайн-игре от гейминг студии, с акцентом на анализ внутриигровых покупок и активности игроков в зависимости от характеристик их персонажей.

## Цель проекта

Получить insights о поведении игроков, которые помогут:
- Оптимизировать игровой баланс между разными расами
- Улучшить монетизацию игры
- Выявить популярные и непопулярные предметы для дальнейшей балансировки

## Задачи проекта

### Исследовательский анализ данных

**Исследование доли платящих игроков**
- Расчет общей доли платящих игроков
- Анализ зависимости доли платящих игроков от расы персонажа

**Исследование внутриигровых покупок**
- Статистический анализ стоимости покупок
- Проверка наличия покупок с нулевой стоимостью
- Анализ популярности эпических предметов

### Решение ad hoc задач

**Зависимость активности игроков от расы персонажа**
- Анализ активности игроков при покупке эпических предметов по разным расам
- Проверка гипотезы о различиях в сложности прохождения для разных рас

Проект состоит из трех частей:

1. **Исследовательский анализ данных**
   - Анализ доли платящих игроков
   - Исследование внутриигровых покупок

2. **Решение ad hoc задач**
   - Изучение зависимости активности игроков от расы персонажа

3. **Выводы и аналитические комментарии**

## Описание данных
Таблица users - содержит информацию об игроках.
id — идентификатор игрока. Первичный ключ таблицы.
tech_nickname — никнейм игрока.
class_id — идентификатор класса. Внешний ключ, который связан со столбцом class_id таблицы classes.
ch_id — идентификатор легендарного умения. Внешний ключ, который связан со столбцом ch_id таблицы skills.
birthdate — дата рождения игрока.
pers_gender — пол персонажа.
registration_dt — дата регистрации пользователя.
server — сервер, на котором играет пользователь.
race_id — идентификатор расы персонажа. Внешний ключ, который связан со столбцом race_id таблицы race.
payer — значение, которое указывает, является ли игрок платящим — покупал ли валюту «райские лепестки» за реальные деньги. 1 — платящий, 0 — не платящий.
lоc_id — идентификатор страны, где находится игрок. Внешний ключ, который связан со столбцом loc_id таблицы country.

Таблица events - содержит информацию о покупках.
transaction_id — идентификатор покупки. Первичный ключ таблицы.
id — идентификатор игрока. Внешний ключ, который связан со столбцом id таблицы users.
date — дата покупки.
time — время покупки.
item_code — код эпического предмета. Внешний ключ, который связан со столбцом item_code таблицы items.
amount — стоимость покупки во внутриигровой валюте «райские лепестки».
seller_id — идентификатор продавца.

Таблица skills - содержит информацию о легендарных умениях.
ch_id — идентификатор легендарного умения. Первичный ключ таблицы.
legendary_skill — название легендарного умения.
Таблица race
Содержит информацию о расах персонажей.
race_id — идентификатор расы персонажа. Первичный ключ таблицы.
race — название расы.

Таблица country - содержит информацию о странах игроков.
lоc_id — идентификатор страны, где находится игрок. Первичный ключ таблицы.
location — название страны.
Таблица classes
Содержит информацию о классах персонажей.
class_id — идентификатор класса. Первичный ключ таблицы.
class — название класса персонажа.

Таблица items - содержит информацию об эпических предметах.
item_code — код эпического предмета. Первичный ключ таблицы.
game_items — название эпического предмета.

## Структура проекта

Файлы проекта:
- `Sprint4.sql` - SQL-запросы для анализа данных
- Текстовый файл с выводами и аналитическими комментариями
