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
- На мобильных игра принудительно использует вертикальную ориентацию.
- Вкладка `Donate` показывает прогресс цели `1429 Robux` донатов и предлагает донаты на `10`, `50`, `100`, `250` или `1000 Robux`.

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

Настройки Roblox experience тоже лежат в `metadata/roblox-metadata.json` в блоке `experienceSettings`.
При деплое GitHub Actions синхронизирует:

- видимость experience;
- voice chat;
- доступные платформы;
- цену private servers;
- social links;
- размер сервера root place.

`Genre`, `Camera` и `Content Maturity` пока лежат в `experienceSettings.dashboardOnly` как желаемое состояние для ручной сверки: текущий Open Cloud sync не умеет применять эти поля API-ключом.

Полезные команды Roblox API:

```sh
node scripts/roblox-metadata.mjs apply
node scripts/roblox-publish.mjs deploy
node scripts/roblox-donation-product.mjs ensure
node scripts/roblox-donation-total.mjs
```

Общая обертка над Roblox Open Cloud лежит в `scripts/lib/roblox-open-cloud.mjs`.

## GitHub Actions deploy

В репозитории есть workflow `.github/workflows/roblox-deploy.yml`.

Он делает:

- проверку Node.js-скриптов;
- установку Rojo на GitHub runner;
- `rojo sourcemap`;
- сборку `build/game-of-life.rbxl`;
- загрузку `.rbxl` как GitHub Actions artifact;
- на push в `main` применяет Roblox metadata, проверяет донатные продукты и публикует place.

Чтобы деплой в Roblox работал из GitHub, добавь secret:

`Settings -> Secrets and variables -> Actions -> New repository secret`

Имя:

```text
ROBLOX_API_KEY
```

Значение: Roblox Open Cloud API key с теми же правами, что лежит локально в `.env`.

## Донат-продукт

Developer Product для цели доната:

- `10 Robux`: `3598501584`
- `50 Robux`: `3598501592`
- `100 Robux`: `3598501597`
- `250 Robux`: `3598501604`
- `1000 Robux`: `3598443222`
- Назначение: собрать `1429 Robux` донатов. После комиссии Roblox 30% это примерно `1000 Robux` для оплаты комиссии релиза и открытия плейса для всех.

Покупки обрабатываются серверным скриптом `DonationReceipts` и увеличивают общий прогресс в DataStore `LifeGridDonations`.
