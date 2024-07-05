Данный скрипт переносит проекты из группы одного репозитория в группу другого

Links:https://python-gitlab.readthedocs.io/en/stable/cli-usage.html


## Подготовка 

В коде прописаны две переменные окружения:

**SOURCE_TOKEN** и **DEST_TOKEN**


Перед использованием их нужно получить в настройках группы (у обоих групп) и экспортировать туда,
где запускается скрипт


```bash
export SOURCE_TOKEN=secret_token1
export DEST_TOKEN=secret_token2

```

Также необходимо добавить публиный ssh ключ (без Passphrase)  в профиль, так как git clone и git push будут использовать
ssh для клонирования и пуша репозиториев:

Profile -> Edit Profile -> SSH Keys -> Вставляем наш публичный ключ


## Использование


Первыйм делом необходимо запустить файлик **gitprepare.sh**. 
Он произведет проверку наши токенов и установит необхожимые пакеты и зависимости 
для корректной работы утилиты **python-gitlab**.


Также в корневой директории будет создан файл **.python-gitlab.cfg**. Именно к нему будет обращаться
python-gitlab для получения **SOURCE_TOKEN'a** и адреса GitLab'а  источника.


Сама утилита используется для получения ID проектов в группе и их последовательного клонирования. 

**(GitLab API не позволяет склонировать более 100 проектов в группе за раз)**



```bash
./gitprepare.sh <source> <project>

```

При попытке выполнения скрипта без параметров или с некорректными параметрами, будет выведена маленькая инструкция по применению




```bash
./migrate.sh [options] <source> <project> <destination> <repo-path>
Options:
  -l, --list-repos           List repos to clone
  -c, --clone                Clone repos (with --mirror)
  -cp, --create-project      Create projects on dest GitLab
  -p, --push                 Change origin and push projects
  -f, --full                 Full execution: get, list, clone repos, create projects on dest GitLab, change remote and push (with --mirror)
  -h, --help                 Show this help message and exit
```

При попытке выполнения скрипта без параметров или с некорректными параметрами, будет выведена маленькая инструкция по применению


Сам код разделен на 7 функций и проверки токенов/ввода:

-  **usage()** - функция, вызываемая при некорректном вводе  

-  **check_existence()** - проверяет корректность ввода групп и токенов (ловит ошибки 404 и 401)

-  **get_repos()** - получает список проектов в группе через python-gitlab

-  **list_repos()** - выводит список проектов в группе через API GitLab

-  **clone_repos(**) - создает папку repos в текущей директории и клонирует(git clone --mirror) туда проекты из функции выше  

-  **create_projects()** - создает проекты с таким же именем как в папке repos в destination repo-path

-  **change_remote_and_push()** - проходится по каждому каталогу репозитория в repos, подставляет имя проекта в origin, удаляет старый  origin и пушит с опцией --mirror





## Замечание

Опция **-cp | --create-project** не обязательна, так как проект клонируется посредством SSH и, 
при его Push'e в новую группу в другой GitLab, он создастся автоматически


## Примеры корректной работы

```bash


./migrate.sh
Usage: ./migrate.sh [options] <source> <project> <destination> <repo-path>
Options:
  -l, --list-repos           List repos to clone
  -c, --clone                Clone repos (with --mirror)
  -cp, --create-project      Create projects on dest GitLab
  -p, --push                 Change origin and push projects
  -f, --full                 Full execution: get, list, clone repos, create projects on dest GitLab, change remote and push (with --mirror)
  -h, --help                 Show this help message and exit

-------------------------------------------------------------

./migrate.sh -y
Unrecognized option '-y'
Usage: ./migrate.sh [options] <source> <project> <destination> <repo-path>
Options:
  -l, --list-repos           List repos to clone
  -c, --clone                Clone repos (with --mirror)
  -cp, --create-project      Create projects on dest GitLab
  -p, --push                 Change origin and push projects
  -f, --full                 Full execution: get, list, clone repos, create projects on dest GitLab, change remote and push (with --mirror)
  -h, --help                 Show this help message and exit


-------------------------------------------------------------

./migrate.sh -l gitlab.source.ru test-migration gitlab.destination.ru gitlab-migration

Group exists.
git@gitlab.source.ru:test-migration/test02.git
git@gitlab.source.ru:test-migration/test01.git

-------------------------------------------------------------

./migrate.sh -c gitlab.source.ru test-migration gitlab.destination.ru gitlab-migration

Group exists.
Cloning git@gitlab.source.ru:test-migration/test02.git ...
Cloning git@gitlab.source.ru:test-migration/test01.git ...

-------------------------------------------------------------

./migrate.sh -cp gitlab.source.ru test-migration gitlab.destination.ru gitlab-migration

Group exists.
Creating project git@gitlab.source.ru:test-migration/test02.git ...
Creating project git@gitlab.source.ru:test-migration/test01.git ...

-------------------------------------------------------------

./migrate.sh -p gitlab.source.ru test-migration gitlab.destination.ru gitlab-migration

Updating origin for repos/test01.git to git@gitlab.destination.ru:infra-openstack/gitlab-migration/test01.git
Note: A branch outside the refs/remotes/ hierarchy was not removed;
to delete it, use:
git branch -d main
Updating origin for repos/test02.git to git@gitlab.destination.ru:infra-openstack/gitlab-migration/test02.git
Note: A branch outside the refs/remotes/ hierarchy was not removed;
to delete it, use:
 git branch -d master

-------------------------------------------------------------

./migrate.sh -f gitlab.source.ru test-migration gitlab.destination.ru gitlab-migration

Group exists.
git@gitlab.source.ru:test-migration/test02.git
git@gitlab.source.ru:test-migration/test01.git
Cloning git@gitlab.source.ru:test-migration/test02.git ...
Cloning git@gitlab.source.ru:test-migration/test01.git ...
Creating project git@gitlab.source.ru:test-migration/test02.git ...
Creating project git@gitlab.source.ru:test-migration/test01.git ...
Updating origin for repos/test01.git to git@gitlab.destination.ru:infra-openstack/gitlab-migration/test01.git
Note: A branch outside the refs/remotes/ hierarchy was not removed;
to delete it, use:
  git branch -d main
Updating origin for repos/test02.git to git@gitlab.destination.ru:infra-openstack/gitlab-migration/test02.git
Note: A branch outside the refs/remotes/ hierarchy was not removed;
to delete it, use:
  git branch -d master

```

