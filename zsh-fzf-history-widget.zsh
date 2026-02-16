#!/usr/bin/env zsh
# Плагин для интерактивного поиска команд из истории с помощью fzf
# Файл: ~/.oh-my-zsh/custom/plugins/zsh-fzf-history-widget/fzf-history-widget.plugin.zsh

# Проверка наличия fzf
if ! command -v fzf &> /dev/null; then
    echo "fzf не установлен. Установите его с помощью: brew install fzf"
    return 1
fi

# Функция для поиска в истории с fzf
fzf-history-widget() {
    # Включаем опцию расширенной истории
    setopt extended_history
    setopt hist_ignore_all_dups
    
    # Получаем текущий ввод в строке
    local selected
    local current_buffer="$BUFFER"
    
    # Используем fc для получения истории с временными метками в формате ISO8601
    # -l: list format, -i: ISO8601 timestamps, 1: с первой записи
    selected=$(fc -li 1 | \
        perl -pe 's/^\s*\d+\s+//; s/^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\s+(.*)$/\x1b[38;5;208m$1\x1b[0m │ $2/' | \
        tail -r | \
        fzf --ansi \
            --no-sort \
            --exact \
            --query="$current_buffer" \
            --prompt="История команд ❯ " \
            --height=40% \
            --reverse \
            --border=rounded \
            --info=inline \
            --bind='right:accept' \
            --bind='shift-up:preview-up' \
            --bind='shift-down:preview-down' \
            --preview-window=hidden \
            --header='↑↓: навигация | →/Enter: выбрать | Esc: отмена' \
            --color='prompt:#ffaf00,pointer:#ffaf00,marker:#ffaf00,header:#87afff' \
        | perl -pe 's/^.*?│\s+//')
    
    # Если команда выбрана, вставляем её в буфер
    if [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
        zle redisplay
    fi
}

# Регистрируем функцию как zsh widget
zle -N fzf-history-widget

# Привязываем к Shift + стрелка вверх
# Для iTerm2 на macOS Shift+Up отправляет последовательность ^[[1;2A
bindkey '^[[1;2A' fzf-history-widget

# Альтернативные привязки на случай других эмуляторов терминала
bindkey '^[OA' fzf-history-widget  # Shift+Up в некоторых терминалах

# Дополнительная функция для принятия подсказок стрелкой вправо
# Эта функция работает с zsh-autosuggestions
if (( ${+ZSH_AUTOSUGGEST_ACCEPT_WIDGETS} )); then
    # Если используется zsh-autosuggestions, стрелка вправо уже настроена
    :
else
    # Базовая функция для стрелки вправо
    forward-char-or-accept-suggestion() {
        if [[ $CURSOR -eq ${#BUFFER} ]]; then
            # Если курсор в конце строки, ничего не делаем
            # (autosuggestions должен обрабатывать это автоматически)
            zle forward-char
        else
            # Иначе просто двигаем курсор вправо
            zle forward-char
        fi
    }
    zle -N forward-char-or-accept-suggestion
    bindkey '^[[C' forward-char-or-accept-suggestion  # Стрелка вправо
fi

# Настройки истории для лучшей работы плагина
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

# Опции истории
setopt EXTENDED_HISTORY          # Записывать временные метки
setopt HIST_EXPIRE_DUPS_FIRST    # Удалять дубликаты при переполнении
setopt HIST_IGNORE_DUPS          # Не записывать повторяющиеся команды
setopt HIST_IGNORE_SPACE         # Игнорировать команды, начинающиеся с пробела
setopt HIST_VERIFY               # Показывать команду перед выполнением из истории
setopt INC_APPEND_HISTORY        # Добавлять команды в историю немедленно
setopt SHARE_HISTORY             # Делиться историей между сессиями

# Информационное сообщение при загрузке плагина
echo "✓ fzf-history-widget загружен. Используйте Shift+↑ для поиска в истории."
