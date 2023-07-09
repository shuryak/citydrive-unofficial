# Неофициальный клиент CityDrive

Для iOS 17 и выше. 
Данное приложение не несёт цели навредить репутации и информационной безопасности сервиса СитиДрайв. По первой же просьбе представителей каршеринга приложение будет убрано из публичного доступа.

<span><img src="img/1.png" style="width:200px;"></span>

#### Структура проекта

```xml
CityDrive
├── NetworkLayer
│   ├── Endpoint
│   │   └── ...
│   ├── Service
│   │   ├── NetworkRouter      <- interface for router
│   │   ├── EndpointType       <- interface for endpoint
│   │   └── ...
│   ├── Manager
│   │   └── ...
│   ├── Encoding               <- json and url parameters encoders
│   │   └── ...
│   └── Model                  <- response and request models
│       └── ...
├── View
│   └── ...
├── Model
│   └── ...
├── ViewModel
│   └── ...
├── MapView
├── CityDriveApp
└── ...                        <- Extentions and Resourses
```

## Технологии

- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Сетевой слой](https://habr.com/ru/articles/443514/)
- [Безопасность токена](https://github.com/jrendel/SwiftKeychainWrapper)
