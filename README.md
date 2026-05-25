# Roblox Game of Life

2D-прототип Conway's Game of Life для Roblox Studio.

В игре есть большое прокручиваемое поле с клетками и нижняя панель управления:

- `Start` запускает и останавливает симуляцию.
- `Next` делает один шаг симуляции.
- `Clear` очищает поле.
- `Random` случайно заполняет поле.
- `Pattern` вставляет классические стартовые фигуры по центру поля.
- Кнопка скорости переключает `Slow`, `Normal` и `Fast`.
- Кнопки `+` и `-` меняют масштаб поля.
- Клик или тап по клетке включает или выключает ее вручную.
- На телефоне поле можно двигать пальцем, поэтому игра удобнее в вертикальном формате.
- Вкладка `Donate` показывает прогресс цели `1000 Robux` и открывает донат-продукт.

Интерфейс автоматически переключается между русским и английским языком по локали Roblox.

## Как запустить через Rojo

1. Откройте Roblox Studio.
2. Откройте или создайте пустой place.
3. Запустите Rojo из этой папки:

   ```sh
   rojo serve
   ```

4. В Roblox Studio подключитесь через Rojo plugin.
5. Нажмите Play. На экране появится 2D-поле Game of Life.

Если Rojo еще не установлен, его можно поставить с официальной страницы: https://rojo.space/

## Автодеплой в Roblox

Скрипт `scripts/roblox-publish.mjs` собирает place-файл через Rojo и может опубликовать его в Roblox.

Проверить сборку без публикации:

```sh
node scripts/roblox-publish.mjs build
```

Собрать и опубликовать новую версию:

```sh
node scripts/roblox-publish.mjs deploy
```

Скрипт берет `universeId` и `placeId` из `metadata/roblox-metadata.json`, а `ROBLOX_API_KEY` из `.env`.

Полезные команды Roblox API:

```sh
node scripts/roblox-metadata.mjs apply
node scripts/roblox-publish.mjs deploy
node scripts/roblox-donation-product.mjs ensure
```

Общая обертка над Roblox Open Cloud лежит в `scripts/lib/roblox-open-cloud.mjs`.

## Донат-продукт

Developer Product для цели доната:

- Product ID: `3598443222`
- Цена: `1000 Robux`
- Назначение: собрать цель, после которой автор оплачивает комиссию релиза и открывает плейс для всех.

Покупки обрабатываются серверным скриптом `DonationReceipts` и увеличивают общий прогресс в DataStore `LifeGridDonations`.
