# shellcheck shell=bash

pamenv-conf.main() {
	local char=
	local mode='MODE_DEFAULT'
	local -i PARSER_LINE_NUMBER=1
	local -i PARSER_COLUMN_NUMBER=0

	declare -A args=()

	bash-args parse "$@" <<-"EOF"
	@flag [help.h] - Show help menu
	@flag [mode] {print} - What mode to operate in
	@arg file - Path to the pam_env.conf file
	EOF

	if [ "${args[help]}" = yes ]; then
		echo "TODO: help menu is wrong. see source"
		printf '%s\n' "$argsHelpText"
	fi

	if [ -z "${argsCommands[0]}" ]; then
		echo "Must pass file name"
		echo "TODO: help menu is wrong. see source"
		printf '%s\n' "$argsHelpText"
	fi

	case "${args[mode]}" in
		print)
			do-print "${argsCommands[0]}"
			;;
		'')
			printf '%s\n' 'Error: pamenv-conf parse must be passed a mode'
			exit 1
			;;
		*)
			printf '%s\n' 'Error: pamenv-conf parse does not have a valid mo de set'
			exit 1
	esac
}

do-print() {
	local file="$1"

	declare -a empty_object=()
	declare -a root_object=()
	bobject set-object --ref root_object '.items' empty_object

	local file_contents=
	file_contents="$(<"$file")"

	local char=
	local var_variable_value=
	# local var_default_value=
	# local var_override_value=

	for ((i=0; i<${#file_contents}; i++)); do
		char="${file_contents:$i:1}"

		if [ "$char" = $'\n' ]; then
			PARSER_COLUMN_NUMBER=0
			PARSER_LINE_NUMBER+=1
		else
			PARSER_COLUMN_NUMBER+=1
		fi

		pamenv_conf.token_history_add

		case "$mode" in
		# State in which parser starts, and before any given TOML construct
		MODE_DEFAULT)
			if [ "$char" = \# ]; then
				mode='MODE_IN_COMMENT'
			elif [ "$char" = $'\n' ]; then
				:
			else
				var_variable_value="$char"
				mode='MODE_IN_VARIABLE_VALUE'
			fi
			;;
		MODE_IN_COMMENT)
			if [ "$char" = $'\n' ]; then
				mode='MODE_DEFAULT'
			fi
			;;
		MODE_IN_VARIABLE_VALUE)
			if [ "$char" = $'\n' ]; then
				:
				mode='MODE_DEFAULT'
			elif [ "$char" = ' ' ] || [ "$char" = $'\t' ]; then
				mode='MODE_SOME_KEY'
			else
				var_variable_value+="$char"
			fi
			;;
		# We are about to encounter a key, but don't know which one it is
		MODE_SOME_KEY)
			if [ "$char" = ' ' ] || [ "$char" = $'\t' ]; then
				:
			elif [ "${file_contents:$i:8}" = DEFAULT= ]; then
				if [ ${var_default_value+x} ]; then
					pamenv_conf.parse_fail "Already specified 'DEFAULT' option. Cannot do it again"
				fi

				mode='MODE_IN_KEY_DEFAULT'
				i=$((i+7))
				local var_default_value=
			elif [ "${file_contents:$i:9}" = OVERRIDE= ]; then
				if [ ${var_override_value+x} ]; then
					pamenv_conf.parse_fail "Already specified 'OVERRIDE' option. Cannot do it again"
				fi
				mode='MODE_IN_KEY_OVERRIDE'
				i=$((i+8))
				local var_override_value=
			elif [ "${file_contents:$i:7}" = DEFAULT ]; then
				pamenv_conf.parse_fail "Must have equal sign after 'DEFAULT'"
			elif [ "${file_contents:$i:8}" = OVERRIDE ]; then
				pamenv_conf.parse_fail "Must have equal sign after 'OVERRIDE'"
			else
				pamenv_conf.parse_fail "Invalid option for variable '$var_variable_value'. Must be either 'DEFAULT' or 'OVERRIDE'"
			fi
			;;
		MODE_IN_KEY_DEFAULT)
			if [ "$char" = $'\n' ]; then
				# TODO: bobject
				mode='MODE_DEFAULT'
			elif [ "$char" = ' ' ] || [ "$char" = $'\t' ]; then
				mode='MODE_SOME_KEY'
			else
				var_default_value=+"$char"
			fi
			;;
		MODE_IN_KEY_OVERRIDE)
			if [ "$char" = $'\n' ]; then
				# TODO: bobject
				mode='MODE_DEFAULT'
			elif [ "$char" = ' ' ] || [ "$char" = $'\t' ]; then
				mode='MODE_SOME_KEY'
			else
				var_override_value=+"$char"
			fi
			;;
		*)
			pamenv_conf.parse_fail "Invalid mode '$mode'"
			;;
		esac
	done

	pamenv_conf.parse_fail "f"
}
declare -a BASH_TOKEN_HISTORY=()

# @description Appends to token history for improved error insight
pamenv_conf.token_history_add() {
	local str=
	printf -v str '%s' "$mode ($char) at $PARSER_LINE_NUMBER:$PARSER_COLUMN_NUMBER"

	BASH_TOKEN_HISTORY+=("$str")

	if [ -n "${DEBUG_BASH_TOML+x}" ]; then
		if [ -n "${BATS_RUN_TMPDIR+x}" ]; then
			printf '%s\n' "$str" >&3
		else
			printf '%s\n' "$str"
		fi
	fi
}

pamenv_conf.parse_fail() {
	local error_message="$1"

	if [ -z "$error_context" ]; then
		error_context="<empty>"
	fi

	local error_output=
	printf -v error_output 'Failed to parse toml:
  -> error: %s
  -> trace:' "$error_message"

	for history_item in "${BASH_TOKEN_HISTORY[@]}"; do
		printf -v error_output '%s\n    - %s' "$error_output" "$history_item"
	done

	printf '%s\n' "$error_output"
	exit 1
}
