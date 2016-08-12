export LC_CTYPE='en_US.UTF-8'
# if [ "$TMUX" = "" ]; then tmux; fi
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set Common env variables
export JAVA_HOME='/usr/lib/jvm/java-8-oracle'

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="flazz"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to disable command auto-correction.
# DISABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git command-not-found gitfast git-extras lein pip python screen ssh-agent sublime urltoos emacs-mode web-search wd)

source $ZSH/oh-my-zsh.sh

# User configuration

PATH="${PATH}:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/lib/postgresql/9.3/bin"
for binPath in $(find "${HOME}/bin" -maxdepth 2 -executable ! -type d -exec dirname {} \; | sort | uniq); do
  PATH="${PATH}:${binPath}"
done
export PATH="$PATH"

fpath=(~/.config/zsh/autocomplete $fpath)
# compsys initialization
autoload -U compinit
compinit
# show completion menu when number of options is at least 2
zstyle ':completion:*' menu select=2
#autoload -U ~/.config/zsh/autocomplete/*(:t)

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# spark
export SPARK_HOME="/opt/spark/spark-1.5.1"

# aliases
alias :q='exit'
alias :w='write_last_command_to_file'
alias :a='append_last_command_to_file'

write_last_command_to_file() {
	$(history | tail -n 1 | awk '{$1=""; print $0}') > $1
}

append_last_command_to_file() {
	$(history | tail -n 1 | awk '{$1=""; print $0}') >> $1
}

gcd() {
  startDir="$(pwd)"
  curPath="$startDir"
  foundProjectRoot=0
  exitStatus=0

  projectFile='.git'

  while [[ "$curPath" != '/' ]]; do
    if [[ -e "${curPath}/${projectFile}" ]]; then
      foundProjectRoot=1
      break
    else
      curPath="$(dirname "$curPath")"
    fi
  done
  if [[ $foundProjectRoot -eq 1 ]]; then
    cd "$curPath"
  else
    echo "[ERROR] not inside a project" >&2
    exitStatus=1
  fi

  return $exitStatus
}
for f in ~/.config/zsh/fns/*; do
    source "$f"
done

export GPGKEY=8427FDA8

# vim: ft=sh
