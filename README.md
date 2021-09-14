# bash-pamenv-conf

Convert `pam_env.conf` syntax to something executable by a POSIX shell

STATUS: ALPHA

```conf
# ./pam_env.conf
FOUR
PAGER	DEFAULT=less
EDITOR	OVERRIDE=vim
```

```sh
$ bash-pamenv-conf ./pam_env.conf
export PAGER="${PAGER:-less}"
export EDITOR='vim'
```

## Installation

Use [Basalt](https://github.com/hyperupcall/basalt), a Bash package manager, to add this project as a dependency

```sh
basalt add 'hyperupcall/bash-pamenv-conf'
```

## Contributing

```sh
git clone 'https://github.com/hyperupcall/bash-pamenv-conf'
cd bash-pamenv-conf
basalt install
```
