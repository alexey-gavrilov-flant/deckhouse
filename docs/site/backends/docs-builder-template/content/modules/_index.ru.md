---
title: Обзор модулей
url: modules/readme.html
layout: modules
---

Deckhouse Platform имеет модульную структуру. Модули могут быть как встроенные в Deckhouse, так и обычные — подключаемые с помощью ресурса `ModuleSource`.

Основное отличие _встроенного_ модуля Deckhouse в том, что встроенный модуль поставляется в составе платформы Deckhouse и имеет общий с Deckhouse релизный цикл. Документацию по встроенным модулям Deckhouse можно найти в разделе [документации Deckhouse](/documentation/v1/).

Обычные модули Deckhouse (подключаемые с помощью ресурса `ModuleSource`) имеют независимый от Deckhouse релизный цикл, то есть могут обновляться независимо от версий Deckhouse. Разработка модулей может вестись командой разработчиков, не связанной с командой разработчиков самого Deckhouse. Работа конкретного модуля может оказывать влияние на работу Deckhouse, хотя мы стремимся к тому, чтобы это влияние не приводило к серьезным последствиям для всей платформы.

В данном разделе представлена информация по модулям Deckhouse, прошедшим предварительное тестирование совместимости и допущенным к использованию совместно с Deckhouse.