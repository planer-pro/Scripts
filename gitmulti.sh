#!/bin/bash

# Проверка, переданы ли логин пользователя и токен
if [ $# -lt 1 ]; then
    echo "Использование: $0 <github_username> [<personal_access_token>]"
    exit 1
fi

# Имя пользователя из аргумента командной строки
USERNAME=$1
TOKEN=${2:-""}  # Токен передается как второй параметр, если указан

# Функция для получения репозиториев
get_repos() {
    local page=$1
    local auth_header=""

    # Если токен передан, добавляем заголовок авторизации
    if [ -n "$TOKEN" ]; then
        auth_header="-H 'Authorization: token $TOKEN'"
    fi

    # Используем GitHub API для получения репозиториев
    curl -s $auth_header "https://api.github.com/users/$USERNAME/repos?page=$page&per_page=100" | \
    jq -r '.[] | "\(.name) - \(.html_url)"'
}

# Функция для клонирования репозитория
clone_repo() {
    local repo_url=$1
    local repo_name=$(echo "$repo_url" | cut -d' ' -f3 | sed 's/https:\/\/github.com\///')
    echo "Клонирование репозитория: $repo_name"
    git clone "$repo_url"
}

# Счетчик страниц
page=1
repos_found=0

# Массив для хранения репозиториев
declare -a REPOS_LIST

echo "Репозитории пользователя $USERNAME:"
echo "----------------------------"

# Цикл для постраничного получения репозиториев
while true; do
    # Получаем репозитории
    current_repos=$(get_repos $page)
    
    # Если репозиториев нет, завершаем цикл
    if [ -z "$current_repos" ]; then
        break
    fi
    
    # Добавляем номера к репозиториям
    numbered_repos=$(echo "$current_repos" | nl -w3 -s'. ')
    
    # Выводим текущую страницу репозиториев с нумерацией
    echo "$numbered_repos"
    
    # Сохраняем репозитории в массив
    while IFS= read -r repo; do
        REPOS_LIST+=("$repo")
    done <<< "$current_repos"
    
    # Подсчет репозиториев
    repos_count=$(echo "$current_repos" | wc -l)
    repos_found=$((repos_found + repos_count))
    
    # Переход к следующей странице
    page=$((page + 1))
done

echo "----------------------------"
echo "Всего репозиториев: $repos_found"

# Интерактивный выбор репозиториев для скачивания
echo "Введите номера репозиториев для скачивания (через пробел)"
echo "Или нажмите Enter для скачивания ВСЕХ репозиториев"
read -p "Номера репозиториев: " selected_repos

# Если ввод пустой, выбираем все репозитории
if [ -z "$selected_repos" ]; then
    echo "Будут скачаны ВСЕ репозитории..."
    selected_repos=$(seq 1 $repos_found)
fi

# Создаем директорию для репозиториев
mkdir -p "$USERNAME-repos"
cd "$USERNAME-repos"

# Скачивание выбранных репозиториев
for num in $selected_repos; do
    # Корректируем номер, так как массив начинается с 0
    index=$((num - 1))
    
    # Проверяем, существует ли репозиторий с таким номером
    if [ $index -lt ${#REPOS_LIST[@]} ]; then
        repo_info="${REPOS_LIST[$index]}"
        repo_url=$(echo "$repo_info" | awk -F' - ' '{print $2}')
        clone_repo "$repo_url"
    else
        echo "Репозиторий с номером $num не найден."
    fi
done

echo "Загрузка репозиториев завершена."
