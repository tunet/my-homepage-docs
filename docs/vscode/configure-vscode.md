# Настройка VSCode



### Установить на WSL2 PHP8.2

```shell
sudo apt update
```

```shell
sudo apt upgrade
```

```shell
sudo add-apt-repository ppa:ondrej/php
```

```shell
sudo apt update
```

```shell
sudo apt install php8.2 php8.2-xml php8.2-xdebug
```



### Добавить файл `.vsocde/settings.json` в проект

```json
{
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.profiles.linux": {
        "bash": {
            "path": "bash",
            "icon": "terminal-bash",
            "args": ["-l"]
        }
    },
    "workbench.tree.indent": 20,
    "editor.rulers": [
        {
            "column": 120,
            "color": "#ffc3b5"
        }
    ],
    "editor.minimap.enabled": false,
    "editor.codeLens": false,
    "phpsab.standard": "./phpcs.xml",
    "phpsab.snifferMode": "onType",
    "phpstan.configFile": "./phpstan.neon",
    // "phpstan.options": [
    //     "--xdebug"
    // ],
    "[php]": {
        "editor.defaultFormatter": "valeryanm.vscode-phpsab",
        "editor.formatOnSave": true
    }
}
```



### Установить необходимые расширения

- [WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) (локально)
- [PHP](https://marketplace.visualstudio.com/items?itemName=DEVSENSE.phptools-vscode) (WSL2)
- [PHP Sniffer & Beautifier](https://marketplace.visualstudio.com/items?itemName=ValeryanM.vscode-phpsab) (WSL2)
- [Makefile Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.makefile-tools) (WSL2)
- [phpstan](https://marketplace.visualstudio.com/items?itemName=SanderRonde.phpstan-vscode) (WSL2)
