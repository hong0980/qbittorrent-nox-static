#!/usr/bin/env bash
#
# cSpell:includeRegExp #.*
#
# Copyright 2020 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @contributors IceCodeNew Stanislas boredazfcuk AdvenT. guillaumedsde inochisa
#
# @credits - https://gist.github.com/notsure2 https://github.com/c0re100/qBittorrent-Enhanced-Edition
#
# Script Formatting - https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format
#
#################################################################################################################################################
# Script version = Major minor patch
#################################################################################################################################################
script_version="2.0.9"
#################################################################################################################################################
# Set some script features - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#################################################################################################################################################
set -a
#################################################################################################################################################
# Unset some variables to set defaults.
#################################################################################################################################################
unset qbt_skip_delete qbt_git_proxy qbt_curl_proxy qbt_install_dir qbt_build_dir qbt_working_dir qbt_modules_test qbt_python_version
#################################################################################################################################################
# Color me up Scotty - define some color values to use as variables in the scripts.
#################################################################################################################################################
color_red="\e[31m" color_red_light="\e[91m"
color_green="\e[32m" color_green_light="\e[92m"
color_yellow="\e[33m" color_yellow_light="\e[93m"
color_blue="\e[34m" color_blue_light="\e[94m"
color_magenta="\e[35m" color_magenta_light="\e[95m"
color_cyan="\e[36m" color_cyan_light="\e[96m"

text_bold="\e[1m" text_dim="\e[2m" text_underlined="\e[4m" text_blink="\e[5m" text_newline="\n"

unicode_red_circle="\e[31m\U2B24\e[0m" unicode_red_light_circle="\e[91m\U2B24\e[0m"
unicode_green_circle="\e[32m\U2B24\e[0m" unicode_green_light_circle="\e[92m\U2B24\e[0m"
unicode_yellow_circle="\e[33m\U2B24\e[0m" unicode_yellow_light_circle="\e[93m\U2B24\e[0m"
unicode_blue_circle="\e[34m\U2B24\e[0m" unicode_blue_light_circle="\e[94m\U2B24\e[0m"
unicode_magenta_circle="\e[35m\U2B24\e[0m" unicode_magenta_light_circle="\e[95m\U2B24\e[0m"
unicode_cyan_circle="\e[36m\U2B24\e[0m" unicode_cyan_light_circle="\e[96m\U2B24\e[0m"
unicode_grey_circle="\e[37m\U2B24\e[0m" unicode_grey_light_circle="\e[97m\U2B24\e[0m"

color_end="\e[0m"

# Function to test color and show outputs in the terminal
_color_test() {
	# Check if the terminal supports color output
	if [[ -t 1 ]]; then
		colour_array=("${color_red}red" "${color_red_light}light red" "${color_green}green" "${color_green_light}light green" "${color_yellow}yellow" "${color_yellow_light}light yellow" "${color_blue}blue" "${color_blue_light}ligh blue" "${color_magenta}magenta" "${color_magenta_light}light magenta" "${color_cyan}cyan" "${color_cyan_light}light cyan")
		formatting_array=("${text_bold}Text Bold" "${text_dim}Text Dim" "${text_underlined}Text Underline" "${text_newline}New line" "${text_blink}Text Blink")
		unicode_array=("${unicode_red_circle}" "${unicode_red_light_circle}" "${unicode_green_circle}" "${unicode_green_light_circle}" "${unicode_yellow_circle}" "${unicode_yellow_light_circle}" "${unicode_blue_circle}" "${unicode_blue_light_circle}" "${unicode_magenta_circle}" "${unicode_magenta_light_circle}" "${unicode_cyan_circle}" "${unicode_cyan_light_circle}" "${unicode_grey_circle}" "${unicode_grey_light_circle}")
		printf '\n'
		for colours in "${colour_array[@]}" "${formatting_array[@]}" "${unicode_array[@]}"; do
			printf '%b\n' "${colours}${color_end}"
		done
		printf '\n'
		exit
	else
		echo "终端不支持彩色输出。"
		exit 1
	fi
}
[[ "${1}" == "ctest" ]] && _color_test # ./scriptname.sh ctest
#######################################################################################################################################################
# Check we are on a supported OS and release.
#######################################################################################################################################################
get_os_info() { # Function to source /etc/os-release and get info from it on demand.
	# shellcheck source=/dev/null
	if source /etc/os-release &> /dev/null; then
		printf "%s" "${!1%_*}" # 扩展部分特定于 Alpine VERSION_ID 格式 1.2.3_alpha，但不会破坏基于 Debian 的格式中的任何内容。 2004年12月24日
	else
		printf "%s" "未知" # 这将使脚本在版本检查时退出并提供有用的原因。
	fi
}

os_id="$(get_os_info ID)"                                                         # 获取此操作系统的 ID。
os_version_codename="$(get_os_info VERSION_CODENAME)"                             # 获取此操作系统的代号。请注意，Alpine 没有唯一的代号。
os_version_id="$(get_os_info VERSION_ID)"                                         # 获取该代号的版本号，例如：10, 20.04, 3.12.4
[[ "$(wc -w <<< "${os_version_id//\./ }")" -eq "2" ]] && alpine_min_version="310" # 考虑版本 3.1 或 3.1.0 中的变化，以确保检查正常工作
[[ "${os_id}" =~ ^(alpine)$ ]] && os_version_codename="alpine"                    # 如果是 alpine，则将代号设置为 alpine。我们稍后会使用代号检查 min v3.10。

# 检查允许的代号或者代号是否是大于 3.10 的 alpine 版本
if [[ ! "${os_version_codename}" =~ ^(alpine|bullseye|bookworm|focal|jammy|noble)$ ]] || [[ "${os_version_codename}" =~ ^(alpine)$ && "${os_version_id//\./}" -lt "${alpine_min_version:-3100}" ]]; then
	printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow} 这不是受支持的操作系统。没有理由继续。${color_end}"
	printf '%b\n\n' " id: ${text_dim}${color_yellow_light}${os_id}${color_end} 代号: ${text_dim}${color_yellow_light}${os_version_codename}${color_end} 版本: ${text_dim}${color_red_light}${os_version_id}${color_end}"
	printf '%b\n\n' " ${unicode_yellow_circle} ${text_dim}这些是支持的平台${color_end}"
	printf '%b\n' " ${color_magenta_light}Debian${color_end} - ${color_blue_light}bullseye${color_end} - ${color_blue_light}bookworm${color_end}"
	printf '%b\n' " ${color_magenta_light}Ubuntu${color_end} - ${color_blue_light}focal${color_end} - ${color_blue_light}jammy${color_end} - ${color_blue_light}noble${color_end}"
	printf '%b\n\n' " ${color_magenta_light}Alpine${color_end} - ${color_blue_light}3.10.0${color_end} ${text_dim}或更高版本${color_end}"
	exit 1
fi
#######################################################################################################################################################
# 从文件中获取环境变量（如果存在），但它将被传递给脚本的开关和标志覆盖
#######################################################################################################################################################
if [[ -f "${PWD}/.qbt_env" ]]; then
	printf '\n%b\n' " ${unicode_magenta_circle} Sourcing .qbt_env file"
	# shellcheck source=/dev/null
	source "${PWD}/.qbt_env"
fi
#######################################################################################################################################################
# Multi arch stuff
#######################################################################################################################################################
# 定义我们使用的所有可用的多拱门 https://github.com/userdocs/qbt-musl-cross-make#readme
declare -gA multi_arch_options
multi_arch_options[default]="skip"
multi_arch_options[armel]="armel"
multi_arch_options[armhf]="armhf"
multi_arch_options[armv7]="armv7"
multi_arch_options[aarch64]="aarch64"
multi_arch_options[x86_64]="x86_64"
multi_arch_options[x86]="x86"
multi_arch_options[s390x]="s390x"
multi_arch_options[powerpc]="powerpc"
multi_arch_options[ppc64el]="ppc64el"
multi_arch_options[mips]="mips"
multi_arch_options[mipsel]="mipsel"
multi_arch_options[mips64]="mips64"
multi_arch_options[mips64el]="mips64el"
multi_arch_options[riscv64]="riscv64"
#######################################################################################################################################################
# 该函数设置了我们使用的一些默认值，但其值可以在运行脚本之前被某些标志覆盖或导出为变量
#######################################################################################################################################################
_set_default_values() {
	# docker 部署不会提示设置时区。
	export DEBIAN_FRONTEND="noninteractive"
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo "Asia/Shanghai" > /etc/timezone

	qBittorrent_version="${qBittorrent_version:-qbittorrent}"
	# 默认构建配置是 qmake + qt5，qbt_build_tool=cmake 或 -c 将使 qt6 和 cmake 默认
	qbt_build_tool="${qbt_build_tool:-qmake}"

	# 默认为空以使用主机本机构建工具。这样我们就可以在受支持的操作系统上构建本机架构并跳过交叉构建工具链
	qbt_cross_name="${qbt_cross_name:-default}"

	# 默认为主机 - 除了默认值之外，我们并没有真正将其用于任何其他用途，因此无需设置它。
	qbt_cross_target="${qbt_cross_target:-${os_id}}"

	# yes 创建调试版本以与 gdb 一起使用 - 禁用剥离 - 由于某种原因 libtorrent b2 版本为 200MB 或更大。 qbt_build_debug=yes 或 -d
	qbt_build_debug="${qbt_build_debug:-no}"

	# github actions 工作流程 - 使用 https://github.com/userdocs/qbt-workflow-files/releases/latest 而不是从各个源位置直接下载。
	# 提供替代源，并且在构建矩阵构建时不会垃圾邮件下载主机。
	qbt_workflow_files="${qbt_workflow_files:-no}"

	# github actions 工作流程 - 使用保存为工件的工作流程文件，而不是从每个矩阵的工作流程文件或主机下载
	qbt_workflow_artifacts="${qbt_workflow_artifacts:-no}"

	# 以这种格式提供 git 用户名和存储库 - 用户名/存储库
	# 在这个仓库中，结构需要像这样 /patches/libtorrent/1.2.11/patch 和/或 /patches/qbittorrent/4.3.1/patch
	# 您的补丁文件将被自动获取并加载那些匹配的标签。
	qbt_patches_url="${qbt_patches_url:-hong0980/qbittorrent-nox-static}"

	# 此版本的 libtorrent 默认没有指定标签或分支。 qbt_libtorrent_version=1.2 或 -lt v1.2.18
	qbt_libtorrent_version="${qbt_libtorrent_version:-2.0}"

	# 使用release Jamfile，除非我们需要相关RC分支的特定修复。
	# 当存在非向后移植的更改时，使用此功能也可能会破坏构建，这将需要自定义的 jamfile
	qbt_libtorrent_master_jamfile="${qbt_libtorrent_master_jamfile:-no}"

	# 默认情况下剥离符号，因为我们需要完整的调试版本才能使用 gdb 进行回溯，因此剥离是一个明智的默认优化。
	qbt_optimise_strip="${qbt_optimise_strip:-yes}"

	# Github 特定操作 - 构建修订 - 工作流程将动态设置此值，以便 URL 不会硬编码到单个存储库
	qbt_revision_url="${qbt_revision_url:-hong0980/qbittorrent-nox-static}"

	# 提供一个路径来检查缓存的本地 git 存储库并使用它们。优先于工作流程文件。
	qbt_cache_dir="${qbt_cache_dir%/}"

	# icu 标签的环境设置
	qbt_skip_icu="${qbt_skip_icu:-yes}"

	# boost 标签的环境设置
	qbt_boost_tag="${qbt_boost_tag:-}"

	# libtorrent 标签的环境设置
	qbt_libtorrent_tag="${qbt_libtorrent_tag:-}"

	# Qt 标签的环境设置
	qbt_qt_tag="${qbt_qt_tag:-}"

	# qbittorrent 标签的环境设置
	qbt_qbittorrent_tag="${qbt_qbittorrent_tag:-}"

	# 我们只使用 python3，但如果出于某种原因需要的话，更改它会更容易。
	qbt_python_version="3"

	# 我们用于包源的 Alpine 存储库
	CDN_URL="http://dl-cdn.alpinelinux.org/alpine/edge/main" # for alpine

	# 在数组中定义可用模块的列表。
	qbt_modules=("all" "install" "glibc" "zlib" "iconv" "icu" "openssl" "boost" "libtorrent" "double_conversion" "qtbase" "qttools" "qbittorrent")

	# 创建这个数组为空。在此数组中列出或添加的模块将从默认模块列表中删除，从而更改所有或安装的行为
	delete=()

	# 创建这个数组为空。在此数组中列出或添加到该数组中的软件包将从默认软件包列表中删除，从而更改已安装依赖项的列表
	delete_pkgs=()
	# 基于 qmake、cmake、strip 和 debug 的使用来更改设置的动态测试
	if [[ "${qbt_build_debug}" = "yes" ]]; then
		qbt_optimise_strip="no"
		qbt_cmake_debug='ON'
		qbt_libtorrent_debug='debug-symbols=on'
		qbt_qbittorrent_debug='--enable-debug'
	else
		qbt_cmake_debug='OFF'
	fi

	# 静态构建
	if [[ ${qbt_static_ish:=no} == "yes" ]]; then
		qbt_ldflags_static=""

		if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then delete+=("glibc"); fi

		if [[ ${qbt_cross_name} != "default" ]]; then
			printf '\n%b\n\n' " ${unicode_red_light_circle} 您不能在交叉编译中使用 ${color_blue_light}-si${color_end} 标志${color_end}"
			exit 1
		fi
	else
		qbt_ldflags_static="-static"
	fi

	# 基于 qmake、cmake、strip 和 debug 的使用来更改设置的动态测试
	if [[ "${qbt_optimise_strip}" = "yes" && "${qbt_build_debug}" = "no" ]]; then
		qbt_strip_qmake='strip'
		qbt_strip_flags='-s'
	else
		qbt_strip_qmake='-nostrip'
		qbt_strip_flags=''
	fi

	# 基于 qmake、cmake、strip 和 debug 的使用来更改设置的动态测试
	case "${qbt_qt_version}" in
		5)
			if [[ "${qbt_build_tool}" != 'cmake' ]]; then
				qbt_build_tool="qmake"
				qbt_use_qt6="OFF"
			fi
			;;&
		6)
			qbt_build_tool="cmake"
			qbt_use_qt6="ON"
			;;&
		"")
			[[ "${qbt_build_tool}" == 'cmake' ]] && qbt_qt_version="6" || qbt_qt_version="5"
			;;&
		*)
			[[ ! "${qbt_qt_version}" =~ ^(5|6)$ ]] && qbt_workflow_files="no"
			[[ "${qbt_build_tool}" == 'qmake' && "${qbt_qt_version}" =~ ^6 ]] && qbt_build_tool="cmake"
			[[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^5 ]] && qbt_build_tool="cmake" qbt_qt_version="6"
			[[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^6 ]] && qbt_use_qt6="ON"
			;;
	esac

	# 如果我们是交叉构建，则引导我们为目标架构所需的交叉构建工具，否则设置本机架构并删除 debian 交叉构建工具
	if [[ "${multi_arch_options[${qbt_cross_name}]}" == "${qbt_cross_name}" ]]; then
		_multi_arch info_bootstrap
	else
		cross_arch="$(uname -m)"
		delete_pkgs+=("crossbuild-essential-${cross_arch}")
	fi

	# 如果是 Alpine，则删除我们不使用的模块并设置所需的包数组
	if [[ "${os_id}" =~ ^(alpine)$ ]]; then
		delete+=("glibc")
		[[ -z "${qbt_cache_dir}" ]] && delete_pkgs+=("coreutils" "gpg")
		qbt_required_pkgs=("autoconf" "automake" "bash" "bash-completion" "build-base" "coreutils" "curl" "git" "gpg" "pkgconf" "libtool" "perl" "python${qbt_python_version}" "python${qbt_python_version}-dev" "py${qbt_python_version}-numpy" "py${qbt_python_version}-numpy-dev" "linux-headers" "ttf-freefont" "graphviz" "cmake" "re2c")
	fi

	# 如果基于 debian，则设置所需的包数组
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		[[ -z "${qbt_cache_dir}" ]] && delete_pkgs+=("autopoint" "gperf")
		qbt_required_pkgs=("autopoint" "gperf" "gettext" "texinfo" "gawk" "bison" "build-essential" "crossbuild-essential-${cross_arch}" "curl" "pkg-config" "automake" "libtool" "git" "openssl" "perl" "python${qbt_python_version}" "python${qbt_python_version}-dev" "python${qbt_python_version}-numpy" "unzip" "graphviz" "re2c")
	fi

	# 除非作为脚本的第一个参数提供，否则默认删除此模块。
	if [[ "${1}" != 'install' ]]; then
		delete+=("install")
	fi

	# 如果 icu 模块作为位置参数提供，则不要删除它。
	# 否则默认跳过 icu，除非提供 -i 标志。
	if [[ "${qbt_skip_icu}" != 'yes' && "${*}" =~ ([[:space:]]|^)"icu"([[:space:]]|$) ]]; then
		qbt_skip_icu="no"
	elif [[ "${qbt_skip_icu}" != "no" ]]; then
		delete+=("icu")
	fi

	# 如果没有指定cmake，配置默认的依赖和模块
	if [[ "${qbt_build_tool}" != 'cmake' ]]; then
		delete+=("double_conversion")
		delete_pkgs+=("unzip" "ttf-freefont" "graphviz" "cmake" "re2c")
	else
		[[ "${qbt_skip_icu}" != "no" ]] && delete+=("icu")
	fi

	# 默认值为 17，但可以通过 env qbt_standard 手动定义 - 在特定情况下，这将被 _set_cxx_standard 函数覆盖
	qbt_standard="${qbt_standard:-17}" qbt_cxx_standard="c++${qbt_standard}"

	# 将工作目录设置为当前位置，所有内容都与该位置相关。
	qbt_working_dir="$(pwd)"

	# 与 printf 一起使用。使用 qbt_working_dir 变量，但 ${HOME} 路径替换为文字 ~
	qbt_working_dir_short="${qbt_working_dir/${HOME}/\~}"

	# Install relative to the script location.
	qbt_install_dir="${qbt_working_dir}/qbt-build"

	# 与 printf 一起使用。使用 qbt_install_dir 变量，但 ${HOME} 路径替换为文字 ~
	qbt_install_dir_short="${qbt_install_dir/${HOME}/\~}"

	# 在我们隔离脚本之前，通过在 _set_build_directory 函数中将 HOME 设置为安装目录来获取本地用户 $PATH。
	qbt_local_paths="$PATH"
}
#######################################################################################################################################################
# 该函数将从 qbt_required_pkgs 数组中检查已定义依赖项的列表。像 python3-dev 这样的应用程序是动态设置的
#######################################################################################################################################################
_check_dependencies() {
	printf '\n%b\n\n' " ${unicode_blue_light_circle} ${text_bold}检查是否安装了所需的核心依赖${color_end}"

	# 从 qbt_required_pkgs 数组中删除 delete_pkgs 中的软件包
	for target in "${delete_pkgs[@]}"; do
		for i in "${!qbt_required_pkgs[@]}"; do
			if [[ "${qbt_required_pkgs[i]}" == "${target}" ]]; then
				unset 'qbt_required_pkgs[i]'
			fi
		done
	done

	# 重建数组以从 0 开始排序索引
	qbt_required_pkgs=("${qbt_required_pkgs[@]}")

	# 这将检查 qbt_required_pkgs 数组中是否有操作系统指定的依赖项，以查看它们是否已安装
	for pkg in "${qbt_required_pkgs[@]}"; do

		if [[ "${os_id}" =~ ^(alpine)$ ]]; then
			pkgman() { apk info -e "${pkg}"; }
		fi

		if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
			pkgman() { dpkg -s "${pkg}"; }
		fi

		if pkgman > /dev/null 2>&1; then
			printf '%b\n' " ${unicode_green_circle} ${pkg}"
		else
			if [[ -n "${pkg}" ]]; then
				deps_installed="no"
				printf '%b\n' " ${unicode_red_circle} ${pkg}"
				qbt_checked_required_pkgs+=("$pkg")
			fi
		fi
	done

	# 检查用户是否能够安装依赖项，如果是则安装，如果否则退出。
	if [[ "${deps_installed}" == "no" ]]; then
		if [[ "$(id -un)" == 'root' ]]; then
			printf '\n%b\n\n' " ${unicode_blue_light_circle} ${color_green}Updating${color_end}"

			if [[ "${os_id}" =~ ^(alpine)$ ]]; then
				apk update --repository="${CDN_URL}"
				apk upgrade --repository="${CDN_URL}"
				apk fix
			fi

			if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
				apt-get update -y
				apt-get upgrade -y
				apt-get autoremove -y
			fi

			[[ -f /var/run/reboot-required ]] && {
				printf '\n%b\n\n' " ${color_red}此计算机需要重新启动才能继续安装。请立即重新启动。${color_end}"
				exit
			}

			printf '\n%b\n\n' " ${unicode_blue_light_circle}${color_green} 安装所需的依赖项${color_end}"

			if [[ "${os_id}" =~ ^(alpine)$ ]]; then
				if ! apk add "${qbt_checked_required_pkgs[@]}" --repository="${CDN_URL}"; then
					printf '\n'
					exit 1
				fi
			fi

			if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
				if ! apt-get install -y "${qbt_checked_required_pkgs[@]}"; then
					printf '\n'
					exit 1
				fi
			fi

			printf '\n%b\n' " ${unicode_green_circle}${color_green} 依赖项已安装！${color_end}"

			deps_installed="yes"
		else
			printf '\n%b\n' " ${text_bold}在使用此脚本之前请请求或安装缺少的核心依赖项${color_end}"

			if [[ "${os_id}" =~ ^(alpine)$ ]]; then
				printf '\n%b\n\n' " ${color_red_light}apk add${color_end} ${qbt_checked_required_pkgs[*]}"
			fi

			if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
				printf '\n%b\n\n' " ${color_red_light}apt-get install -y${color_end} ${qbt_checked_required_pkgs[*]}"
			fi

			exit
		fi
	fi

	# 所有依赖项检查均已通过 print
	if [[ "${deps_installed}" != "no" ]]; then
		printf '\n%b\n' " ${unicode_green_circle}${text_bold} 所有依赖均已通过，继续构建${color_end}"
	fi
}
#######################################################################################################################################################
# 该函数将版本字符串转换为数字以进行比较。
#######################################################################################################################################################
_semantic_version() {
	local test_array
	read -ra test_array < <(printf "%s" "${@//./ }")
	printf "%d%03d%03d%03d" "${test_array[@]}"
}
#######################################################################################################################################################
# _print_env
#######################################################################################################################################################
_print_env() {
	printf '\n%b\n\n' " ${unicode_yellow_circle} 默认环境变量${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_version=\"${color_green_light}${qbt_libtorrent_version}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_qt_version=\"${color_green_light}${qbt_qt_version}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_build_tool=\"${color_green_light}${qbt_build_tool}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_cross_name=\"${color_green_light}${qbt_cross_name}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_patches_url=\"${color_green_light}${qbt_patches_url}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_skip_icu=\"${color_green_light}${qbt_skip_icu}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_boost_tag=\"${color_green_light}${github_tag[boost]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_tag=\"${color_green_light}${github_tag[libtorrent]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_qt_tag=\"${color_green_light}${github_tag[qtbase]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_qbittorrent_tag=\"${color_green_light}${github_tag[qbittorrent]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_master_jamfile=\"${color_green_light}${qbt_libtorrent_master_jamfile}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_workflow_files=\"${color_green_light}${qbt_workflow_files}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_workflow_artifacts=\"${color_green_light}${qbt_workflow_artifacts}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_cache_dir=\"${color_green_light}${qbt_cache_dir}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_optimise_strip=\"${color_green_light}${qbt_optimise_strip}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_build_debug=\"${color_green_light}${qbt_build_debug}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_standard=\"${color_green_light}${qbt_standard}${color_yellow_light}\"${color_end}"
	printf '%b\n\n' " ${color_yellow_light}  qbt_static_ish=\"${color_green_light}${qbt_static_ish}${color_yellow_light}\"${color_end}"
}
#######################################################################################################################################################
# These functions set the cxx standard dynmically based on the libtorrent versions, qt version and qbittorrent combinations
#######################################################################################################################################################
_qt_std_cons() {
	[[ "${qbt_qt_version}" == "6" ]] && cxx_check="yes"
	printf '%s' "${cxx_check:-no}"
}

_libtorrent_std_cons() {
	[[ "${github_tag[libtorrent]}" =~ ^(RC_1_2|RC_2_0)$ ]] && cxx_check="yes"
	[[ "${github_tag[libtorrent]}" =~ ^v1\.2\. && "$(_semantic_version "${github_tag[libtorrent]/v/}")" -ge "$(_semantic_version "1.2.20")" ]] && cxx_check="yes"
	[[ "${github_tag[libtorrent]}" =~ ^v2\.0\. && "$(_semantic_version "${github_tag[libtorrent]/v/}")" -ge "$(_semantic_version "2.0.10")" ]] && cxx_check="yes"
	printf '%s' "${cxx_check:-no}"
}

_qbittorrent_std_cons() {
	[[ "${github_tag[qbittorrent]}" == "master" ]] && cxx_check="yes"
	[[ "${github_tag[qbittorrent]}" =~ ^release- && "$(_semantic_version "${github_tag[qbittorrent]/release-/}")" -ge "$(_semantic_version "4.6.0")" ]] && cxx_check="yes"
	printf '%s' "${cxx_check:-no}"
}

_set_cxx_standard() {
	if [[ $(_qt_std_cons) == "yes" && $(_libtorrent_std_cons) == "yes" && $(_qbittorrent_std_cons) == "yes" ]]; then
		if [[ "${os_version_codename}" =~ ^(alpine|bookworm|jammy|noble)$ ]]; then
			qbt_standard="20" qbt_cxx_standard="c++${qbt_standard}"
		fi
	fi
}

#######################################################################################################################################################
# 这些函数根据 libtorrent 版本、qt 版本和 qbittorrent 组合动态设置一些构建条件
#######################################################################################################################################################
_qbittorrent_build_cons() {
	[[ "${github_tag[qbittorrent]}" == "master" ]] && disable_qt5="yes"
	[[ "${github_tag[qbittorrent]}" == "v5_0_x" ]] && disable_qt5="yes"
	[[ "${github_tag[qbittorrent]}" =~ ^release- && "$(_semantic_version "${github_tag[qbittorrent]/release-/}")" -ge "$(_semantic_version "5.0.0")" ]] && disable_qt5="yes"
	printf '%s' "${disable_qt5:-no}"
}

_set_build_cons() {
	if [[ $(_qbittorrent_build_cons) == "yes" && "${qbt_qt_version}" == "5" ]]; then
		printf '\n%b\n\n' " ${text_blink}${unicode_red_light_circle}${color_end} ${color_yellow}qBittorrent ${color_magenta}${github_tag[qbittorrent]}${color_yellow} 不支持 ${color_red}Qt5${color_yellow}。请使用 ${color_green}Qt6${color_yellow} 或 qBittorrent ${color_green}v4${color_yellow} 标签。${color_end}"
		if [[ -d "${release_info_dir}" ]]; then touch "${release_info_dir}/disable-qt5"; fi # qbittorrent v5 transtion - workflow specific
		exit                                                                                # non error exit to not upset github actions - just skip the step
	fi
}
#######################################################################################################################################################
# 这是一个命令测试函数：_cmd exit 1
#######################################################################################################################################################
_cmd() {
	if ! "${@}"; then
		printf '\n%b\n\n' " 命令：${color_red_light}${*}${color_end} 失败"
		exit 1
	fi
}
#######################################################################################################################################################
# This is a command test function to test build commands for failure
#######################################################################################################################################################
_post_command() {
	outcome=("${PIPESTATUS[@]}")
	[[ -n "${1}" ]] && command_type="${1}"
	if [[ "${outcome[*]}" =~ [1-9] ]]; then
		printf '\n%b\n' " ${unicode_red_circle}${color_red} 错误：${color_end} ${command_type:-tested} 命令生成的退出代码大于 0 - 检查日志 ${color_end}"
		printf '\n%b\n' " ${unicode_yellow_circle}${color_yellow} 警告：${color_end} 开发人员很容易被疯狂的问题吓到或困惑，如果您看到此警告并且无法自行解决问题，请打开首先是这个仓库的一个问题："
		printf '\n%b\n\n' " ${unicode_blue_circle}${color_blue_light} https://github.com/userdocs/qbittorrent-nox-static/issues ${color_end}"
		exit 1
	fi
}
#######################################################################################################################################################
# This function is to test a directory exists before attempting to cd and fail with and exit code if it doesn't.
#######################################################################################################################################################
_pushd() {
	if ! pushd "$@" &> /dev/null; then
		printf '\n%b\n' "该目录不存在。有问题"
		printf '\n%b\n\n' "${color_red_light}${1}${color_end}"
		exit 1
	fi
}

_popd() {
	if ! popd &> /dev/null; then
		printf '%b\n' "此目录不存在。有问题"
		exit 1
	fi
}
#######################################################################################################################################################
# 该函数确保 tee 所需的日志目录和路径存在
#######################################################################################################################################################
_tee() {
	[[ "$#" -eq 1 && "${1%/*}" =~ / ]] && mkdir -p "${1%/*}"
	[[ "$#" -eq 2 && "${2%/*}" =~ / ]] && mkdir -p "${2%/*}"
	command tee "$@"
}
#######################################################################################################################################################
# error functions
#######################################################################################################################################################
_error_tag() {
	[[ "${github_tag[*]}" =~ error_tag ]] && {
		printf '\n'
		exit
	}
}
#######################################################################################################################################################
# _curl 测试下载功能 - 默认无代理 - _curl 是测试功能，_curl_curl 是命令功能
#######################################################################################################################################################
_curl_curl() {
	"$(type -P curl)" -sNL4fq --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 "${qbt_curl_proxy[@]}" "${@}"
}

_curl() {
	if ! _curl_curl "${@}"; then
		return 1
	fi
}
#######################################################################################################################################################
# git test 下载功能 - 默认无代理 - git 是测试功能，_git_git 是命令功能
#######################################################################################################################################################
_git_git() {
	"$(type -P git)" "${qbt_git_proxy[@]}" "${@}"
}

_git() {
	if [[ "${2}" == '-t' ]]; then
		git_test_cmd=("${1}" "${2}" "${3}")
	else
		[[ "${9}" =~ https:// ]] && git_test_cmd=("${9}")   # qttools 的下载文件夹功能中排名第九
		[[ "${11}" =~ https:// ]] && git_test_cmd=("${11}") # 我们的下载文件夹功能中第 11 位
	fi

	if ! _curl -fIL "${git_test_cmd[@]}" &> /dev/null; then
		printf '\n%b\n\n' " ${color_yellow}Git 测试 1: 您的代理设置或网络连接存在问题${color_end}"
		exit
	fi

	status="$(
		_git_git ls-remote -qht --refs --exit-code "${git_test_cmd[@]}" &> /dev/null
		printf "%s" "${?}"
	)"

	if [[ "${2}" == '-t' && "${status}" -eq '0' ]]; then
		printf '%b\n' "${3}"
	elif [[ "${2}" == '-t' && "${status}" -ge '1' ]]; then
		printf '%b\n' 'error_tag'
	else
		if ! _git_git "${@}"; then
			printf '\n%b\n\n' " ${color_yellow}Git 测试 2: 您的代理设置或网络连接存在问题${color_end}"
			exit
		fi
	fi
}

_test_git_ouput() {
	if [[ "${1}" == 'error_tag' ]]; then
		printf '\n%b\n' " ${text_blink}${unicode_red_light_circle}${color_end} ${color_yellow}提供的${2}标签${color_red}${3}${color_end}${color_yellow}为无效${color_end}"
	fi
}
#######################################################################################################################################################
# Boost URL test function
#######################################################################################################################################################
_boost_url() {
	if [[ "${github_tag[boost]}" =~ \.beta ]]; then
		local boost_asset="${github_tag[boost]/\.beta/\.b}"
		local boost_asset_type="beta"
	else
		local boost_asset="${github_tag[boost]}"
		local boost_asset_type="release"
	fi

	local boost_url_array=(
		"https://boostorg.jfrog.io/artifactory/main/${boost_asset_type}/${github_tag[boost]/boost-/}/source/${boost_asset//[-\.]/_}.tar.gz"
		"https://archives.boost.io/${boost_asset_type}/${github_tag[boost]/boost-/}/source/${boost_asset//[-\.]/_}.tar.gz"
	)

	for url in "${boost_url_array[@]}"; do
		if _curl -sfLI "${url}" &> /dev/null; then
			boost_url_status="200"
			source_archive_url[boost]="${url}"
			source_default[boost]="file"
			break
		else
			boost_url_status="403"
			source_default[boost]="folder"
		fi
	done
}
#######################################################################################################################################################
# Debug stuff
#######################################################################################################################################################
_debug() {
	if [[ "${script_debug_urls}" == "yes" ]]; then
		mapfile -t github_url_sorted < <(printf '%s\n' "${!github_url[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}github_url${color_end}"
		for n in "${github_url_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${github_url[$n]}${color_end}" #: ${github_url[$n]}"
		done

		mapfile -t github_tag_sorted < <(printf '%s\n' "${!github_tag[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}github_tag${color_end}"
		for n in "${github_tag_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${github_tag[$n]}${color_end}" #: ${github_url[$n]}"
		done

		mapfile -t app_version_sorted < <(printf '%s\n' "${!app_version[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}app_version${color_end}"
		for n in "${app_version_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${app_version[$n]}${color_end}" #: ${github_url[$n]}"
		done

		mapfile -t source_archive_url_sorted < <(printf '%s\n' "${!source_archive_url[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}source_archive_url${color_end}"
		for n in "${source_archive_url_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${source_archive_url[$n]}${color_end}" #: ${github_url[$n]}"
		done

		mapfile -t qbt_workflow_archive_url_sorted < <(printf '%s\n' "${!qbt_workflow_archive_url[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}qbt_workflow_archive_url${color_end}"
		for n in "${qbt_workflow_archive_url_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${qbt_workflow_archive_url[$n]}${color_end}" #: ${github_url[$n]}"
		done

		mapfile -t source_default_sorted < <(printf '%s\n' "${!source_default[@]}" | sort)
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}source_default${color_end}"
		for n in "${source_default_sorted[@]}"; do
			printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${source_default[$n]}${color_end}" #: ${github_url[$n]}"
		done

		printf '\n%b\n' " ${unicode_magenta_circle} ${color_yellow_light}Tests${color_end}"
		printf '\n%b\n' " ${color_green_light}boost_url_status:${color_end} ${color_blue_light}${boost_url_status}${color_end}"
		printf '%b\n' " ${color_green_light}test_url_status:${color_end} ${color_blue_light}${test_url_status}${color_end}"

		printf '\n'
		exit
	fi
}
#######################################################################################################################################################
# 该函数全局设置一些编译器标志 - b2 设置在 _installation_modules 函数中设置的 ~/user-config.jam 中设置
#######################################################################################################################################################
_custom_flags_set() {
	CXXFLAGS="${qbt_optimize/*/${qbt_optimize} }-std=${qbt_cxx_standard} ${qbt_ldflags_static} -w -Wno-psabi -I${include_dir}"
	CPPFLAGS="${qbt_optimize/*/${qbt_optimize} }${qbt_ldflags_static} -w -Wno-psabi -I${include_dir}"
	LDFLAGS="${qbt_optimize/*/${qbt_optimize} }${qbt_ldflags_static} ${qbt_strip_flags} -L${lib_dir} -pthread"
}

_custom_flags_reset() {
	CXXFLAGS="${qbt_optimize/*/${qbt_optimize} } -w -std=${qbt_cxx_standard}"
	CPPFLAGS="${qbt_optimize/*/${qbt_optimize} } -w"
	LDFLAGS=""
}
#######################################################################################################################################################
# 此函数将完整的 qbittorrent-nox 静态版本安装到 root 的 /usr/local/bin 或非 root 的 ${HOME}/bin
#######################################################################################################################################################
_install_qbittorrent() {
	if [[ -f "${qbt_install_dir}/completed/qbittorrent-nox" ]]; then
		if [[ "$(id -un)" == 'root' ]]; then
			mkdir -p "/usr/local/bin"
			cp -vrf "${qbt_install_dir}/completed/qbittorrent-nox" "/usr/local/bin"
		else
			mkdir -p "${HOME}/bin"
			cp -vrf "${qbt_install_dir}/completed/qbittorrent-nox" "${LOCAL_USER_HOME}/bin"
		fi

		printf '\n%b\n' " ${unicode_blue_light_circle} qbittorrent-nox 已安装！${color_end}"
		printf '\n%b\n' " 使用以下命令运行它："
		[[ "$(id -un)" == 'root' ]] && printf '\n%b\n\n' " ${color_green}qbittorrent-nox${color_end}" || printf '\n%b\n\n' " ${color_green}~/bin/qbittorrent-nox${color_end}"
		exit
	else
		printf '\n%b\n\n' " ${unicode_red_circle} qbittorrent-nox 尚未构建到定义的安装目录:"
		printf '\n%b\n' "${color_green}${qbt_install_dir_short}/completed${color_end}"
		printf '\n%b\n\n' "请先使用脚本构建然后安装"
		exit
	fi
}
#######################################################################################################################################################
# Script Version check
#######################################################################################################################################################
_script_version() {
	script_version_remote="$(_curl -sL "${script_url}" | sed -rn 's|^script_version="(.*)"$|\1|p')"

	if [[ "$(_semantic_version "${script_version}")" -lt "$(_semantic_version "${script_version_remote}")" ]]; then
		printf '\n%b\n' " ${text_blink}${unicode_red_circle}${color_end} 脚本更新可用！版本 - ${color_yellow_light} 本地：${color_red_light}${script_version}${color_end} ${color_yellow_light} 远程：${color_green_light}${script_version_remote}${color_end}"
		printf '\n%b\n' " ${unicode_green_circle} curl -sLo ${BASH_SOURCE[0]} https://git.io/qbstatic${color_end}"
	elif [[ "$(_semantic_version "${script_version}")" -gt "$(_semantic_version "${script_version_remote}")" ]]; then
		printf '\n%b\n' " ${unicode_green_circle} 脚本版本: ${color_red_light}${script_version}-dev${color_end}"
	else
		printf '\n%b\n' " ${unicode_green_circle} 脚本版本: ${color_green_light}${script_version}${color_end}"
	fi
}
#######################################################################################################################################################
# URL test for normal use and proxy use - make sure we can reach google.com before processing the URL functions
#######################################################################################################################################################
_test_url() {
	test_url_status="$(_curl -o /dev/null --head --write-out '%{http_code}' "https://github.com")"
	if [[ "${test_url_status}" -eq "200" ]]; then
		printf '\n%b\n' " ${unicode_green_circle} 测试 URL = ${color_green}已通过${color_end}"
	else
		printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow}测试 URL 失败:${color_end} ${color_yellow_light}您的代理设置或网络连接可能存在问题${color_end}"
		exit
	fi
}
#######################################################################################################################################################
# This function sets the build and installation directory. If the argument -b is used to set a build directory that directory is set and used.
# If nothing is specified or the switch is not used it defaults to the hard-coded path relative to the scripts location - qbittorrent-build
#######################################################################################################################################################
_set_build_directory() {
	if [[ -n "${qbt_build_dir}" ]]; then
		if [[ "${qbt_build_dir}" =~ ^/ ]]; then
			qbt_install_dir="${qbt_build_dir}"
			qbt_install_dir_short="${qbt_install_dir/${HOME}/\~}"
		else
			qbt_install_dir="${qbt_working_dir}/${qbt_build_dir}"
			qbt_install_dir_short="${qbt_working_dir_short}/${qbt_build_dir}"
		fi
	fi

	# Set lib and include directory paths based on install path.
	include_dir="${qbt_install_dir}/include"
	lib_dir="${qbt_install_dir}/lib"

	# Define some build specific variables
	LOCAL_USER_HOME="${HOME}" # Get the local user's home dir path before we contain HOME to the build dir.
	HOME="${qbt_install_dir}"
	PATH="${qbt_install_dir}/bin${PATH:+:${qbt_local_paths}}"
	PKG_CONFIG_PATH="${lib_dir}/pkgconfig"
}
#######################################################################################################################################################
# This function is where we set your URL and github tag info that we use with other functions.
#######################################################################################################################################################
_set_module_urls() {
	# Update check url for the _script_version function
	script_url="https://raw.githubusercontent.com/userdocs/qbittorrent-nox-static/master/qbittorrent-nox-static.sh"
	##########################################################################################################################################################
	# Create all the arrays now
	##########################################################################################################################################################
	declare -gA github_url github_tag app_version source_archive_url qbt_workflow_archive_url qbt_workflow_override source_default
	##########################################################################################################################################################
	# Configure the github_url associative array for all the applications this script uses and we call them as ${github_url[app_name]}
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		github_url[cmake_ninja]="https://github.com/userdocs/qbt-cmake-ninja-crossbuilds.git"
		github_url[glibc]="https://sourceware.org/git/glibc.git"
	else
		github_url[ninja]="https://github.com/userdocs/qbt-ninja-build.git"
	fi
	github_url[zlib]="https://github.com/zlib-ng/zlib-ng.git"
	github_url[iconv]="https://git.savannah.gnu.org/git/libiconv.git"
	github_url[icu]="https://github.com/unicode-org/icu.git"
	github_url[double_conversion]="https://github.com/google/double-conversion.git"
	github_url[openssl]="https://github.com/openssl/openssl.git"
	github_url[boost]="https://github.com/boostorg/boost.git"
	github_url[libtorrent]="https://github.com/arvidn/libtorrent.git"
	github_url[qtbase]="https://github.com/qt/qtbase.git"
	github_url[qttools]="https://github.com/qt/qttools.git"
	github_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent.git"
	##########################################################################################################################################################
	# Configure the github_tag associative array for all the applications this script uses and we call them as ${github_tag[app_name]}
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		github_tag[cmake_ninja]="$(_git_git ls-remote -q -t --refs "${github_url[cmake_ninja]}" | awk '{sub("refs/tags/", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
		if [[ "${os_version_codename}" =~ ^(bullseye|focal)$ ]]; then
			github_tag[glibc]="glibc-2.31"
		elif [[ "${os_version_codename}" =~ ^(bookworm|jammy)$ ]]; then
			github_tag[glibc]="glibc-2.38"
		else # "$(_git_git ls-remote -q -t --refs https://sourceware.org/git/glibc.git | awk '/\/tags\/glibc-[0-9]\.[0-9]{2}$/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
			github_tag[glibc]="glibc-2.39"
		fi
	else
		github_tag[ninja]="$(_git_git ls-remote -q -t --refs "${github_url[ninja]}" | awk '/v/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	fi
	github_tag[zlib]="develop"
	#github_tag[iconv]="$(_git_git ls-remote -q -t --refs "${github_url[iconv]}" | awk '{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[iconv]="v$(_curl "https://github.com/userdocs/qbt-workflow-files/releases/latest/download/dependency-version.json" | sed -rn 's|(.*)"iconv": "(.*)",|\2|p')"
	github_tag[icu]="$(_git_git ls-remote -q -t --refs "${github_url[icu]}" | awk '/\/release-/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[double_conversion]="$(_git_git ls-remote -q -t --refs "${github_url[double_conversion]}" | awk '/v/{sub("refs/tags/", "");sub("(.*)(v6|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[openssl]="$(_git_git ls-remote -q -t --refs "${github_url[openssl]}" | awk '/openssl/{sub("refs/tags/", "");sub("(.*)(v6|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
	github_tag[boost]=$(_git_git ls-remote -q -t --refs "${github_url[boost]}" | awk '{sub("refs/tags/", "");sub("(.*)(rc|alpha|beta|-bgl)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)
	github_tag[libtorrent]="$(_git_git ls-remote -q -t --refs "${github_url[libtorrent]}" | awk '/'"v${qbt_libtorrent_version}"'/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qtbase]="$(_git_git ls-remote -q -t --refs "${github_url[qtbase]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qttools]="$(_git_git ls-remote -q -t --refs "${github_url[qttools]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qbittorrent]="$(_git_git ls-remote -q -t --refs "${github_url[qbittorrent]}" | awk '{sub("refs/tags/", "");sub("(.*)(-[^0-9].*|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	##########################################################################################################################################################
	# Configure the app_version associative array for all the applications this script uses and we call them as ${app_version[app_name]}
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		app_version[cmake_debian]="${github_tag[cmake_ninja]%_*}"
		app_version[ninja_debian]="${github_tag[cmake_ninja]#*_}"
		app_version[glibc]="${github_tag[glibc]#glibc-}"
	else
		app_version[cmake]="$(apk info -d cmake | awk '/cmake-/{sub("(cmake-)", "");sub("(-r)", ""); print $1 }' | sort -r | head -n1)"
		app_version[ninja]="${github_tag[ninja]#v}"
	fi
	app_version[zlib]="$(_curl "https://raw.githubusercontent.com/zlib-ng/zlib-ng/${github_tag[zlib]}/zlib.h.in" | sed -rn 's|#define ZLIB_VERSION "(.*)"|\1|p' | sed 's/\.zlib-ng//g')"
	app_version[iconv]="${github_tag[iconv]#v}"
	app_version[icu]="${github_tag[icu]#release-}"
	app_version[double_conversion]="${github_tag[double_conversion]#v}"
	app_version[openssl]="${github_tag[openssl]#openssl-}"
	app_version[boost]="${github_tag[boost]#boost-}"
	app_version[libtorrent]="${github_tag[libtorrent]#v}"
	app_version[qtbase]="$(printf '%s' "${github_tag[qtbase]#v}" | sed 's/-lts-lgpl//g')"
	app_version[qttools]="$(printf '%s' "${github_tag[qttools]#v}" | sed 's/-lts-lgpl//g')"
	app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
	##########################################################################################################################################################
	# 为该脚本使用的所有应用程序配置 source_archive_url 关联数组，我们将它们称为 ${source_archive_url[app_name]}
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		source_archive_url[cmake_ninja]="https://github.com/userdocs/qbt-cmake-ninja-crossbuilds/releases/latest/download/${os_id}-${os_version_codename}-cmake-$(dpkg --print-architecture).tar.xz"
		source_archive_url[glibc]="https://ftpmirror.gnu.org/gnu/libc/${github_tag[glibc]}.tar.xz"
	fi
	source_archive_url[zlib]="https://github.com/zlib-ng/zlib-ng/archive/refs/heads/develop.tar.gz"
	source_archive_url[iconv]="https://mirrors.dotsrc.org/gnu/libiconv/$(grep -Eo 'libiconv-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(_curl https://mirrors.dotsrc.org/gnu/libiconv/) | sort -V | tail -1)"
	source_archive_url[icu]="https://github.com/unicode-org/icu/releases/download/${github_tag[icu]}/icu4c-${app_version[icu]/-/_}-src.tgz"
	source_archive_url[double_conversion]="https://github.com/google/double-conversion/archive/refs/tags/${github_tag[double_conversion]}.tar.gz"
	source_archive_url[openssl]="https://github.com/openssl/openssl/releases/download/${github_tag[openssl]}/${github_tag[openssl]}.tar.gz"
	_boost_url # function to test and set the boost url and more
	source_archive_url[libtorrent]="https://github.com/arvidn/libtorrent/releases/download/${github_tag[libtorrent]}/libtorrent-rasterbar-${github_tag[libtorrent]#v}.tar.gz"

	read -ra qt_version_short_array <<< "${app_version[qtbase]//\./ }"
	qt_version_short="${qt_version_short_array[0]}.${qt_version_short_array[1]}"

	if [[ "${qbt_qt_version}" =~ ^6 ]]; then
		source_archive_url[qtbase]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qtbase]}/submodules/qtbase-everywhere-src-${app_version[qtbase]}.tar.xz"
		source_archive_url[qttools]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qttools]}/submodules/qttools-everywhere-src-${app_version[qttools]}.tar.xz"
	else
		source_archive_url[qtbase]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qtbase]}/submodules/qtbase-everywhere-opensource-src-${app_version[qtbase]}.tar.xz"
		source_archive_url[qttools]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qttools]}/submodules/qttools-everywhere-opensource-src-${app_version[qttools]}.tar.xz"
	fi

	source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/${github_tag[qbittorrent]}.tar.gz"
	##########################################################################################################################################################
	# Configure the qbt_workflow_archive_url associative array for all the applications this script uses and we call them as ${qbt_workflow_archive_url[app_name]}
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		qbt_workflow_archive_url[cmake_ninja]="${source_archive_url[cmake_ninja]}"
		qbt_workflow_archive_url[glibc]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/glibc.${github_tag[glibc]#glibc-}.tar.xz"
	fi
	qbt_workflow_archive_url[zlib]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/zlib.tar.xz"
	qbt_workflow_archive_url[iconv]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/iconv.tar.xz"
	qbt_workflow_archive_url[icu]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/icu.tar.xz"
	qbt_workflow_archive_url[double_conversion]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/double_conversion.tar.xz"
	qbt_workflow_archive_url[openssl]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/openssl.tar.xz"
	qbt_workflow_archive_url[boost]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/boost.tar.xz"
	qbt_workflow_archive_url[libtorrent]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/libtorrent.${github_tag[libtorrent]/v/}.tar.xz"
	qbt_workflow_archive_url[qtbase]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qt${qbt_qt_version:0:1}base.tar.xz"
	qbt_workflow_archive_url[qttools]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qt${qbt_qt_version:0:1}tools.tar.xz"
	qbt_workflow_archive_url[qbittorrent]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qbittorrent.tar.xz"
	##########################################################################################################################################################
	# Configure workflow override options
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		qbt_workflow_override[cmake_ninja]="no"
		qbt_workflow_override[glibc]="no"
	fi
	qbt_workflow_override[zlib]="no"
	qbt_workflow_override[iconv]="no"
	qbt_workflow_override[icu]="no"
	qbt_workflow_override[double_conversion]="no"
	qbt_workflow_override[openssl]="no"
	qbt_workflow_override[boost]="no"
	qbt_workflow_override[libtorrent]="no"
	qbt_workflow_override[qtbase]="no"
	qbt_workflow_override[qttools]="no"
	qbt_workflow_override[qbittorrent]="no"
	##########################################################################################################################################################
	# Configure the default source type we use for the download function
	##########################################################################################################################################################
	if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
		source_default[cmake_ninja]="file"
		source_default[glibc]="file"
	fi
	source_default[zlib]="file"
	source_default[iconv]="file"
	source_default[icu]="file"
	source_default[double_conversion]="file"
	source_default[openssl]="file"
	source_default[boost]="file"
	source_default[libtorrent]="file"
	source_default[qtbase]="file"
	source_default[qttools]="file"
	source_default[qbittorrent]="file"
	##########################################################################################################################################################
	#
	##########################################################################################################################################################
	return
}
#######################################################################################################################################################
# This function verifies the module names from the array qbt_modules in the default values function.
#######################################################################################################################################################
_installation_modules() {
	# Delete modules - using the the delete array to unset them from the qbt_modules array
	for target in "${delete[@]}"; do
		for deactivated in "${!qbt_modules[@]}"; do
			[[ "${qbt_modules[${deactivated}]}" == "${target}" ]] && unset 'qbt_modules[${deactivated}]'
		done
	done
	unset target deactivated

	# For any modules params passed, test that they exist in the qbt_modules array or set qbt_modules_test to fail
	for passed_params in "${@}"; do
		if [[ ! "${qbt_modules[*]}" =~ (^|[^[:alpha:]])${passed_params}([^[:alpha:]]|$) ]]; then
			qbt_modules_test="fail"
		fi
	done
	unset passed_params

	if [[ "${qbt_modules_test}" != 'fail' && "${#}" -ne '0' ]]; then
		if [[ "${1}" == "all" ]]; then
			# If all is passed as a module and once the params check = pass has triggered this condition, remove to from the qbt_modules array to leave only the modules to be activated
			unset 'qbt_modules[0]'
			# Rebuild the qbt_modules array so it is indexed starting from 0 after we have modified and removed items from it previously.
			qbt_modules=("${qbt_modules[@]}")
		else # Only activate the module passed as a param and leave the rest defaulted to skip
			unset 'qbt_modules[0]'
			read -ra qbt_modules_skipped <<< "${qbt_modules[@]}"
			declare -gA skip_modules
			for selected in "${@}"; do
				for full_list in "${!qbt_modules_skipped[@]}"; do
					[[ "${selected}" == "${qbt_modules_skipped[full_list]}" ]] && qbt_modules_skipped[full_list]="${color_magenta_light}${selected}${color_end}"
				done
			done
			unset selected
			qbt_modules=("${@}")
		fi

		for modules_skip in "${qbt_modules[@]}"; do
			skip_modules["${modules_skip}"]="no"
		done
		unset modules_skip

		# Create the directories we need.
		mkdir -p "${qbt_install_dir}/logs"
		mkdir -p "${PKG_CONFIG_PATH}"
		mkdir -p "${qbt_install_dir}/completed"

		# Set some python variables we need.
		python_major="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[0])")"
		python_minor="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[1])")"

		python_short_version="${python_major}.${python_minor}"

		printf '%b\n' "using gcc : : : <cflags>${qbt_optimize/*/${qbt_optimize} }-std=${qbt_cxx_standard} <cxxflags>${qbt_optimize/*/${qbt_optimize} }-std=${qbt_cxx_standard} ;${text_newline}using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" > "${HOME}/user-config.jam"

		# printf 构建目录。
		printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} 安装前缀${color_end} : ${color_cyan_light}${qbt_install_dir_short}${color_end}"

		# 一些基本帮助
		printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} 脚本帮助${color_end}：${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-h${color_end}"
	fi
}
#######################################################################################################################################################
# This function will test to see if a Jamfile patch file exists via the variable patches_github_url for the tag used.
#######################################################################################################################################################
_apply_patches() {
	[[ -n "${1}" ]] && app_name="${1}"
	# Start to define the default master branch we will use by transforming the app_version[libtorrent] variable to underscores. The result is dynamic and can be: RC_1_0, RC_1_1, RC_1_2, RC_2_0 and so on.
	default_jamfile="${app_version[libtorrent]//./\_}"

	# Remove everything after second underscore. Occasionally the tag will be short, like v2.0 so we need to make sure not remove the underscore if there is only one present.
	if [[ $(grep -o '_' <<< "${default_jamfile}" | wc -l) -le 1 ]]; then
		default_jamfile="RC_${default_jamfile}"
	elif [[ $(grep -o '_' <<< "${default_jamfile}" | wc -l) -ge 2 ]]; then
		default_jamfile="RC_${default_jamfile%_*}"
	fi

	if [[ "${app_name}" == "bootstrap" ]]; then
		for module_patch in "${qbt_modules[@]}"; do
			[[ -n "${app_version["${module_patch}"]}" ]] && mkdir -p "${qbt_install_dir}/patches/${module_patch}/${app_version["${module_patch}"]}/source"
		done
		unset module_patch
		printf '\n%b\n\n' " ${unicode_yellow_circle} 默认已创建的目录：${color_end}"

		for patch_info in "${qbt_modules[@]}"; do
			[[ -n "${app_version["${patch_info}"]}" ]] && printf '%b\n' " ${color_cyan_light} ${qbt_install_dir_short}/patches/${patch_info}/${app_version["${patch_info}"]}${color_end}"
		done
		unset patch_info
		printf '\n%b\n' " ${unicode_cyan_circle} 如果在这些目录中找到名为 ${color_cyan_light}patch${color_end} 的补丁文件，它将被应用到相关的模块。"
	else
		patch_dir="${qbt_install_dir}/patches/${app_name}/${app_version[${app_name}]}"

		# local
		patch_file="${patch_dir}/patch"
		patch_url_file="${patch_dir}/url" # A file with a url to raw patch info
		# remote
		patch_file_remote="https://raw.githubusercontent.com/${qbt_patches_url}/master/patches/${app_name}/${app_version[${app_name}]}"

		if [[ "${app_name}" == "libtorrent" ]]; then
			patch_jamfile="${patch_dir}/Jamfile"
			patch_jamfile_url="https://raw.githubusercontent.com/${qbt_patches_url}/master/patches/${app_name}/${app_version[${app_name}]}/Jamfile"
		fi

		# Order of patch file preference
		# 1. Local patch file - A custom patch file in the module version folder matching the build configuration
		# 2. Local url file - A custom url to a raw patch file in the module version folder matching the build configuration
		# 3. Remote patch file using the patch_file_remote/patch - A custom url to a raw patch file
		# 4. Remote url file using patch_file_remote/url - A url to a raw patch file in the patch repo

		[[ "${source_default[${app_name}]}" == "folder" && ! -d "${qbt_cache_dir}/${app_name}" ]] && printf '\n' # cosmetics

		_patch_url() {
			patch_url="$(< "${patch_url_file}")"
			if _curl --create-dirs "${patch_url}" -o "${patch_file}"; then
				printf '%b\n\n' " ${unicode_green_circle} ${color_red}从 ${color_red_light}remote:url${color_end} - ${color_magenta_light}${app_name}${color_end} 修补${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_yellow_light}${patch_url}${color_end}"
			fi
		}

		if [[ -f "${patch_file}" ]]; then # If the patch file exists in the module version folder matching the build configuration then use this.
			printf '%b\n\n' " ${unicode_green_circle} 从 ${color_red_light}本地:patch${color_end} 打补丁 - ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_cyan_light}${patch_file}${color_end}"
		elif [[ -f "${patch_url_file}" ]]; then # If a remote URL file exists in the module version folder matching the build configuration then use this to create the patch file for the next check
			_patch_url
		else # Else check that if there is a remotely host patch file available in the patch repo
			if _curl --create-dirs "${patch_file_remote}/patch" -o "${patch_file}"; then
				printf '%b\n\n' " ${unicode_green_circle} ${color_red}从远程打补丁${color_end} - ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_yellow_light}${patch_file_remote}/patch${color_end}"
			elif _curl --create-dirs "${patch_file_remote}/url" -o "${patch_url_file}"; then
				_patch_url
			fi
		fi

		# Libtorrent specific stuff
		if [[ "${app_name}" == "libtorrent" ]]; then
			if [[ "${qbt_libtorrent_master_jamfile}" == "yes" ]]; then
				_curl --create-dirs "https://raw.githubusercontent.com/arvidn/libtorrent/${default_jamfile}/Jamfile" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '%b\n\n' " ${unicode_green_circle}${color_red} 使用 libtorrent 分支主 Jamfile 文件${color_end}"
			elif [[ -f "${patch_dir}/Jamfile" ]]; then
				cp -vf "${patch_dir}/Jamfile" "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '%b\n\n' " ${unicode_green_circle}${color_red} 使用现有的自定义 Jamfile 文件${color_end}"
			else
				if _curl --create-dirs "${patch_jamfile_url}" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"; then
					printf '%b\n\n' " ${unicode_green_circle}${color_red} 使用下载的自定义 Jamfile 文件${color_end}"
				else
					printf '%b\n\n' " ${unicode_green_circle}${color_red} 使用 libtorrent ${github_tag[libtorrent]} Jamfile 文件${color_end}"
				fi
			fi
		fi

		# Patch files
		[[ -f "${patch_file}" ]] && patch -p1 < "${patch_file}"

		# Copy modified files from source directory
		if [[ -d "${patch_dir}/source" && "$(ls -A "${patch_dir}/source")" ]]; then
			printf '%b\n\n' " ${unicode_red_circle} ${color_yellow_light}从补丁源目录复制文件${color_end}"
			cp -vrf "${patch_dir}/source/". "${qbt_dl_folder_path}/"
		fi
	fi
}
#######################################################################################################################################################
# A unified download function to handle the processing of various options and directions the script can take.
#######################################################################################################################################################
_download() {
	_pushd "${qbt_install_dir}"

	[[ -n "${1}" ]] && app_name="${1}"

	# The location we download source archives and folders to
	qbt_dl_dir="${qbt_install_dir}"
	qbt_dl_file_path="${qbt_dl_dir}/${app_name}.tar.xz"
	qbt_dl_folder_path="${qbt_dl_dir}/${app_name}"

	if [[ "${qbt_workflow_files}" == "no" ]] || [[ "${qbt_workflow_override[${app_name}]}" == "yes" ]]; then
		qbt_dl_source_url="${source_archive_url[${app_name}]}"
		source_type="source"
	fi

	if [[ "${qbt_workflow_files}" == "yes" && "${qbt_workflow_override[${app_name}]}" == "no" ]] || [[ "${qbt_workflow_artifacts}" == 'yes' ]]; then
		qbt_dl_source_url="${qbt_workflow_archive_url[${app_name}]}"
		[[ "${qbt_workflow_files}" == "yes" ]] && source_type="workflow"
		[[ "${qbt_workflow_artifacts}" == "yes" ]] && source_type="artifact"
	fi

	[[ -n "${qbt_cache_dir}" ]] && _cache_dirs
	[[ "${source_default[${app_name}]}" == "file" ]] && _download_file
	[[ "${source_default[${app_name}]}" == "folder" ]] && _download_folder

	return 0
}
#######################################################################################################################################################
#
#######################################################################################################################################################
_cache_dirs() {
	# If the path is not starting with / then make it a full path by prepending the qbt_working_dir path
	if [[ ! "${qbt_cache_dir}" =~ ^/ ]]; then
		qbt_cache_dir="${qbt_working_dir}/${qbt_cache_dir}"
	fi

	qbt_dl_dir="${qbt_cache_dir}"
	qbt_dl_file_path="${qbt_dl_dir}/${app_name}.tar.xz"
	qbt_dl_folder_path="${qbt_dl_dir}/${app_name}"

	if [[ "${qbt_workflow_files}" == "yes" && "${qbt_workflow_override[${app_name}]}" == "no" || "${app_name}" == "cmake_ninja" ]]; then
		source_default["${app_name}"]="file"
	elif [[ "${qbt_cache_dir_options}" == "bs" || -d "${qbt_dl_folder_path}" ]]; then
		source_default["${app_name}"]="folder"
	fi

	return
}
#######################################################################################################################################################
# This function is for downloading git releases based on their tag.
#######################################################################################################################################################
_download_folder() {
	# 设置此项以避免克隆某些模块时出现警告
	_git_git config --global advice.detachedHead false

	# 如果不使用工件，请在我们再次下载或复制它们之前删除构建目录中的源文件（如果存在）
	[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
	[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"

	# 如果提供的路径中不存在 app_name 缓存目录并且我们正在引导，则使用此 echo
	if [[ "${qbt_cache_dir_options}" == "bs" && ! -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} 将 ${color_magenta_light}${app_name}${color_end} 名称 ${color_yellow_light}${github_tag[${app_name}]}${color_end} 缓存到${color_cyan_light}${color_cyan_light}${qbt_dl_folder_path}${color_end}${color_end}来自${color_yellow_light}${color_yellow_light}${github_url[${app_name}]}${color_end}"
	fi

	# 如果缓存目录已打开并且 app_name 文件夹不存在，则通过克隆默认源获取文件夹
	if [[ "${qbt_cache_dir_options}" != "bs" && ! -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} 正在下载 ${color_magenta_light}${app_name}${color_end} 名称 ${color_yellow_light}${github_tag[${app_name}]}${color_end} to ${color_cyan_light}${color_cyan_light}${qbt_dl_folder_path}${color_end}${color_end} 下载到 ${color_yellow_light}${color_yellow_light}${github_url[${app_name}]}${color_end}"
	fi

	if [[ ! -d "${qbt_dl_folder_path}" ]]; then
		if [[ "${app_name}" =~ qttools ]]; then
			_git clone --no-tags --single-branch --branch "${github_tag[${app_name}]}" -j"$(nproc)" --depth 1 "${github_url[${app_name}]}" "${qbt_dl_folder_path}"
			_pushd "${qbt_dl_folder_path}"
			git submodule update --force --recursive --init --remote --depth=1 --single-branch
			_popd
		else
			_git clone --no-tags --single-branch --branch "${github_tag[${app_name}]}" --shallow-submodules --recurse-submodules -j"$(nproc)" --depth 1 "${github_url[${app_name}]}" "${qbt_dl_folder_path}"
		fi
	fi

	# 如果提供的路径中存在 app_name 缓存目录并且我们正在引导，则使用它
	if [[ "${qbt_cache_dir_options}" == "bs" && -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_green_circle} ${color_blue_light}${app_name}${color_end} - 正在更新目录 ${color_cyan_light}${qbt_dl_folder_path}${color_end}"
		_pushd "${qbt_dl_folder_path}"

		if git ls-remote -qh --refs --exit-code "${github_url[${app_name}]}" "${github_tag[${app_name}]}" &> /dev/null; then
			_git_git fetch origin "${github_tag[${app_name}]}:${github_tag[${app_name}]}" --no-tags --depth=1 --recurse-submodules --update-head-ok
		fi

		if git ls-remote -qt --refs --exit-code "${github_url[${app_name}]}" "${github_tag[${app_name}]}" &> /dev/null; then
			_git_git fetch origin tag "${github_tag[${app_name}]}" --no-tags --depth=1 --recurse-submodules --update-head-ok
		fi

		_git_git checkout "${github_tag[${app_name}]}"
		_popd
	fi

	if [[ "${qbt_cache_dir_options}" != "bs" && -n "${qbt_cache_dir}" && -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} 从缓存 ${color_cyan_light}${qbt_cache_dir}/${app_name}${color_end} 中拷贝 ${color_magenta_light}${app_name}${color_end}（标签为 ${color_yellow_light}${github_tag[${app_name}]}${color_end}）到 ${color_cyan_light}${qbt_install_dir}/${app_name}${color_end}"
		cp -vrf "${qbt_dl_folder_path}" "${qbt_install_dir}/"
	fi

	if [[ "${qbt_cache_dir_options}" != "bs" ]]; then
		mkdir -p "${qbt_install_dir}/${app_name}${sub_dir}"
		_pushd "${qbt_install_dir}/${app_name}${sub_dir}"
	fi

	printf '%s' "${github_url[${app_name}]}" |& _tee "${qbt_install_dir}/logs/${app_name}_github_url.log" > /dev/null

	return
}
#######################################################################################################################################################
# 该函数用于下载源代码档案
#######################################################################################################################################################
_download_file() {
	if [[ -f "${qbt_dl_file_path}" && "${qbt_workflow_artifacts}" == "no" ]]; then
		# 这会检查存档是否损坏或为空，检查顶级文件夹，如果没有结果则退出，即存档为空 - 这样我们就可以进行 rm 和空替换
		_cmd grep -Eqom1 "(.*)[^/]" <(tar tf "${qbt_dl_file_path}")
		# 删除任何现有的解压档案和档案
		rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"
	fi

	if [[ "${qbt_cache_dir_options}" != "bs" && ! -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} 下载 ${color_yellow_light}${source_type}${color_end} ${color_yellow_light}${qbt_dl_source_url}${color_end} - ${color_magenta_light}${app_name}${color_end} 文件到 ${color_cyan_light}${qbt_dl_file_path}${color_end}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" == "bs" && ! -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n' " ${unicode_blue_light_circle} 将 ${color_magenta_light}${app_name}${color_end} 的 ${color_yellow_light}${source_type}${color_end} 文件缓存到 ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end} - ${color_yellow_light}${qbt_dl_source_url}${color_end}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" == "bs" && -f "${qbt_dl_file_path}" ]]; then
		[[ "${qbt_cache_dir_options}" == "bs" ]] && printf '\n%b\n' " ${unicode_blue_light_circle} 更新 ${color_magenta_light}${app_name}${color_end} 缓存的 ${color_yellow_light}${source_type}${color_end} 文件，从 - ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" != "bs" && -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} 从 - ${color_cyan_light}${color_cyan_light} 中提取 ${color_magenta_light}${app_name}${color_end} 缓存的 ${color_yellow_light}${source_type}${color_end} 文件 ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end}"
	fi

	if [[ "${qbt_workflow_artifacts}" == "no" ]]; then
		# 使用curl下载远程源文件
		if [[ "${qbt_cache_dir_options}" = "bs" || ! -f "${qbt_dl_file_path}" ]]; then
			_curl --create-dirs "${qbt_dl_source_url}" -o "${qbt_dl_file_path}"
		fi
	fi

	# 将提取的目录名称设置为 var 以方便使用或删除它
	qbt_dl_folder_path="${qbt_install_dir}/$(tar tf "${qbt_dl_file_path}" | head -1 | cut -f1 -d"/")"

	printf '%b\n' "${qbt_dl_source_url}" |& _tee "${qbt_install_dir}/logs/${app_name}_${source_type}_archive_url.log" > /dev/null

	[[ "${app_name}" == "cmake_ninja" ]] && additional_cmds=("--strip-components=1")

	if [[ "${qbt_cache_dir_options}" != "bs" ]]; then
		_cmd tar xf "${qbt_dl_file_path}" -C "${qbt_install_dir}" "${additional_cmds[@]}"
		# 如果我们通过源档案下载它，则不需要 cd 进入 boost

		if [[ "${app_name}" == "cmake_ninja" ]]; then
			_delete_function
		else
			mkdir -p "${qbt_dl_folder_path}${sub_dir}"
			_pushd "${qbt_dl_folder_path}${sub_dir}"
		fi
	fi

	unset additional_cmds
	return
}
#######################################################################################################################################################
# 静态库链接修复：检查 $lib_dir 中库的 *.so 和 *.a 版本，并将 *.so 链接更改为指向静态库，例如libdl.a
#######################################################################################################################################################
_fix_static_links() {
	log_name="${app_name}"
	mapfile -t library_list < <(find "${lib_dir}" -maxdepth 1 -exec bash -c 'basename "$0" ".${0##*.}"' {} \; | sort | uniq -d)
	for file in "${library_list[@]}"; do
		if [[ "$(readlink "${lib_dir}/${file}.so")" != "${file}.a" ]]; then
			ln -fsn "${file}.a" "${lib_dir}/${file}.so"
			printf 's%b\n' "${lib_dir}${file}.so changed to point to ${file}.a" |& _tee -a "${qbt_install_dir}/logs/${log_name}-fix-static-links.log" > /dev/null
		fi
	done
	return
}
_fix_multiarch_static_links() {
	if [[ -d "${qbt_install_dir}/${qbt_cross_host}" ]]; then
		log_name="${app_name}"
		multiarch_lib_dir="${qbt_install_dir}/${qbt_cross_host}/lib"
		mapfile -t library_list < <(find "${multiarch_lib_dir}" -maxdepth 1 -exec bash -c 'basename "$0" ".${0##*.}"' {} \; | sort | uniq -d)
		for file in "${library_list[@]}"; do
			if [[ "$(readlink "${multiarch_lib_dir}/${file}.so")" != "${file}.a" ]]; then
				ln -fsn "${file}.a" "${multiarch_lib_dir}/${file}.so"
				printf '%b\n' "${multiarch_lib_dir}${file}.so changed to point to ${file}.a" |& _tee -a "${qbt_install_dir}/logs/${log_name}-fix-static-links.log" > /dev/null
			fi
		done
		return
	fi
}
#######################################################################################################################################################
# 此功能用于删除我们不再需要的文件和文件夹
#######################################################################################################################################################
_delete_function() {
	[[ "${app_name}" != "cmake_ninja" ]] && printf '\n'
	if [[ "${qbt_skip_delete}" != "yes" ]]; then
		printf '%b\n' " ${unicode_green_circle}${color_red_light} 删除 ${app_name} 缓存的安装文件和文件夹${color_end}"
		[[ -f "${qbt_dl_file_path}" && "${qbt_workflow_artifacts}" == "no" ]] && rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d "${qbt_dl_folder_path}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		_pushd "${qbt_working_dir}"
	else
		printf '%b\n' " ${unicode_yellow_circle}${color_red_light} 跳过 ${app_name} 删除${color_end}"
	fi
}
#######################################################################################################################################################
# 安装cmake
#######################################################################################################################################################
_cmake() {
	if [[ "${qbt_build_tool}" == 'cmake' ]]; then
		printf '\n%b\n' " ${unicode_blue_light_circle} ${color_blue_light}检查是否需要安装cmake和ninja${color_end}"
		mkdir -p "${qbt_install_dir}/bin"

		if [[ "${os_id}" =~ ^(debian|ubuntu)$ ]]; then
			if [[ "$(cmake --version 2> /dev/null | awk 'NR==1{print $3}')" != "${app_version[cmake_debian]}" ]]; then
				_download cmake_ninja
				_post_command "Debian cmake and ninja installation"

				printf '\n%b\n' " ${unicode_yellow_circle} 使用 cmake: ${color_yellow_light}${app_version[cmake_debian]}"
				printf '\n%b\n' " ${unicode_yellow_circle} 使用 ninja: ${color_yellow_light}${app_version[ninja_debian]}"
			fi
		fi

		if [[ "${os_id}" =~ ^(alpine)$ ]]; then
			if [[ "$("${qbt_install_dir}/bin/ninja" --version 2> /dev/null | sed 's/\.git//g')" != "${app_version[ninja]}" ]]; then
				_curl "https://github.com/userdocs/qbt-ninja-build/releases/latest/download/ninja-$(apk info --print-arch)" -o "${qbt_install_dir}/bin/ninja"
				_post_command ninja
				chmod 700 "${qbt_install_dir}/bin/ninja"

				printf '\n%b\n' " ${unicode_yellow_circle} 使用 cmake: ${color_yellow_light}${app_version[cmake]}"
				printf '\n%b\n' " ${unicode_yellow_circle} 使用 ninja: ${color_yellow_light}${app_version[ninja]}"
			fi
		fi
		printf '\n%b\n' " ${unicode_green_circle} ${color_green_light}cmake 和 ninja 已安装并可以使用${color_end}"
	fi
	_pushd "${qbt_working_dir}"
}
#######################################################################################################################################################
# 该函数处理脚本的多架构动态。
#######################################################################################################################################################
_multi_arch() {
	if [[ "${multi_arch_options[${qbt_cross_name:-default}]}" == "${qbt_cross_name}" ]]; then
		if [[ "${os_id}" =~ ^(alpine|debian|ubuntu)$ ]]; then
			[[ "${1}" != "bootstrap" ]] && printf '\n%b\n' " ${unicode_green_circle}${color_yellow_light} 使用多架构 - 架构：${qbt_cross_name} 主机：${os_id} 目标：${qbt_cross_target}${color_end}"
			case "${qbt_cross_name}" in
				armel)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="arm-linux-musleabi"
							qbt_zlib_arch="armv5"
							;;&
						debian | ubuntu)
							qbt_cross_host="arm-linux-gnueabi"
							;;&
						*)
							bitness="32"
							cross_arch="armel"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				armhf)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="armhf"
							qbt_cross_host="arm-linux-musleabihf"
							qbt_zlib_arch="armv6"
							;;&
						debian | ubuntu)
							cross_arch="armel"
							qbt_cross_host="arm-linux-gnueabihf"
							;;&
						*)
							bitness="32"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				armv7)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="armv7"
							qbt_cross_host="armv7l-linux-musleabihf"
							qbt_zlib_arch="armv7"
							;;&
						debian | ubuntu)
							cross_arch="armhf"
							qbt_cross_host="arm-linux-gnueabihf"
							;;&
						*)
							bitness="32"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				aarch64)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="aarch64"
							qbt_cross_host="aarch64-linux-musl"
							qbt_zlib_arch="aarch64"
							;;&
						debian | ubuntu)
							cross_arch="arm64"
							qbt_cross_host="aarch64-linux-gnu"
							;;&
						*)
							bitness="64"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-aarch64"
							qbt_cross_qtbase="linux-aarch64-gnu-g++"
							;;
					esac
					;;
				x86_64)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="x86_64"
							qbt_cross_host="x86_64-linux-musl"
							qbt_zlib_arch="x86_64"
							;;&
						debian | ubuntu)
							cross_arch="amd64"
							qbt_cross_host="x86_64-linux-gnu"
							;;&
						*)
							bitness="64"
							qbt_cross_boost=""
							qbt_cross_openssl="linux-x86_64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				x86)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="x86"
							qbt_cross_host="i686-linux-musl"
							qbt_zlib_arch="i686"
							;;&
						debian | ubuntu)
							cross_arch="i386"
							qbt_cross_host="i686-linux-gnu"
							;;&
						*)
							bitness="32"
							qbt_cross_openssl="linux-x86"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				s390x)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="s390x-linux-musl"
							qbt_zlib_arch="s390x"
							;;&
						debian | ubuntu)
							qbt_cross_host="s390x-linux-gnu"
							;;&
						*)
							cross_arch="s390x"
							bitness="64"
							qbt_cross_boost="gcc-s390x"
							qbt_cross_openssl="linux64-s390x"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				powerpc)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="powerpc-linux-musl"
							qbt_zlib_arch="ppc"
							;;&
						debian | ubuntu)
							qbt_cross_host="powerpc-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="powerpc"
							qbt_cross_boost="gcc-ppc"
							qbt_cross_openssl="linux-ppc"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				ppc64el)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="powerpc64le-linux-musl"
							qbt_zlib_arch="ppc64el"
							;;&
						debian | ubuntu)
							qbt_cross_host="powerpc64le-linux-gnu"
							;;&
						*)
							bitness="64"
							cross_arch="ppc64el"
							qbt_cross_boost="gcc-ppc64el"
							qbt_cross_openssl="linux-ppc64le"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				mips)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips-linux-musl"
							qbt_zlib_arch="mips"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="mips"
							qbt_cross_boost="gcc-mips"
							qbt_cross_openssl="linux-mips32"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				mipsel)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mipsel-linux-musl"
							qbt_zlib_arch="mipsel"
							;;&
						debian | ubuntu)
							qbt_cross_host="mipsel-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="mipsel"
							qbt_cross_boost="gcc-mipsel"
							qbt_cross_openssl="linux-mips32"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				mips64)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips64-linux-musl"
							qbt_zlib_arch="mips64"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips64-linux-gnuabi64"
							;;&
						*)
							bitness="64"
							cross_arch="mips64"
							qbt_cross_boost="gcc-mips64"
							qbt_cross_openssl="linux64-mips64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				mips64el)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips64el-linux-musl"
							qbt_zlib_arch="mips64el"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips64el-linux-gnuabi64"
							;;&
						*)
							bitness="64"
							cross_arch="mips64el"
							qbt_cross_boost="gcc-mips64el"
							qbt_cross_openssl="linux64-mips64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				riscv64)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="riscv64-linux-musl"
							qbt_zlib_arch="mips64"
							;;&
						debian)
							printf '\n%b\n\n' " ${unicode_red_circle} 架构 ${color_yellow_light}${qbt_cross_name}${color_end} 只能在 Alpine OS 主机上交叉构建"
							exit 1
							;;
						ubuntu)
							qbt_cross_host="riscv64-linux-gnu"
							;;&
						*)
							bitness="64"
							cross_arch="riscv64"
							qbt_cross_boost="gcc-riscv64"
							qbt_cross_openssl="linux64-riscv64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
			esac

			[[ "${1}" == 'info_bootstrap' ]] && return

			export CHOST="${qbt_cross_host}"
			export CC="${qbt_cross_host}-gcc"
			export AR="${qbt_cross_host}-ar"
			export CXX="${qbt_cross_host}-g++"

			mkdir -p "${qbt_install_dir}/logs"

			if [[ "${1}" == 'bootstrap' || "${qbt_cache_dir_options}" == "bs" ]] && [[ -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" ]]; then
				rm -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz"
			fi

			if [[ "${qbt_cross_target}" =~ ^(alpine)$ ]]; then
				if [[ "${1}" == 'bootstrap' || "${qbt_cache_dir_options}" == "bs" || ! -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" ]]; then
					printf '\n%b\n' " ${unicode_blue_light_circle} 正在下载 ${color_magenta_light}${qbt_cross_host}.tar.gz${color_end} 交叉工具链 - ${color_cyan_light}https://github.com/userdocs/qbt-musl-cross-make/releases/latest/download/${qbt_cross_host}.tar.xz${color_end}"
					_curl --create-dirs "https://github.com/userdocs/qbt-musl-cross-make/releases/latest/download/${qbt_cross_host}.tar.xz" -o "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz"
				else
					printf '\n%b\n' " ${unicode_blue_light_circle} 正在解压 ${color_magenta_light}${qbt_cross_host}.tar.gz${color_end} 交叉工具链 - ${color_cyan_light}${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.xz${color_end}"
				fi

				tar xf "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" --strip-components=1 -C "${qbt_install_dir}"

				_fix_multiarch_static_links "${qbt_cross_host}"
			fi

			multi_glibc=("--host=${qbt_cross_host}")                                                # ${multi_glibc[@]}
			multi_iconv=("--host=${qbt_cross_host}")                                                # ${multi_iconv[@]}
			multi_icu=("--host=${qbt_cross_host}" "-with-cross-build=${qbt_install_dir}/icu/cross") # ${multi_icu[@]}
			multi_openssl=("./Configure" "${qbt_cross_openssl}")                                    # ${multi_openssl[@]}
			multi_qtbase=("-xplatform" "${qbt_cross_qtbase}")                                       # ${multi_qtbase[@]}

			if [[ "${qbt_build_tool}" == 'cmake' ]]; then
				multi_libtorrent=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")        # ${multi_libtorrent[@]}
				multi_double_conversion=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++") # ${multi_double_conversion[@]}
				multi_qbittorrent=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")       # ${multi_qbittorrent[@]}
			else
				printf '%b\n' "using gcc : ${qbt_cross_boost#gcc-} : ${qbt_cross_host}-g++ : <cflags>${qbt_optimize/*/${qbt_optimize} }-std=${qbt_cxx_standard} <cxxflags>${qbt_optimize/*/${qbt_optimize} }-std=${qbt_cxx_standard} ;${text_newline}using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" > "${HOME}/user-config.jam"
				multi_libtorrent=("toolset=${qbt_cross_boost:-gcc}") # ${multi_libtorrent[@]}
				multi_qbittorrent=("--host=${qbt_cross_host}")       # ${multi_qbittorrent[@]}
			fi
			return
		else
			printf '\n%b\n\n' " ${unicode_red_circle} Multiarch 仅适用于 Alpine Linux（本机或 docker）${color_end}"
			exit 1
		fi
	else
		multi_openssl=("./config") # ${multi_openssl[@]}
		return
	fi
}
#######################################################################################################################################################
# Github Actions 发布信息
#######################################################################################################################################################
_release_info() {
	_error_tag

	printf '\n%b\n' " ${unicode_green_circle} ${color_yellow_light}释放引导${color_end}"

	release_info_dir="${qbt_install_dir}/release_info"

	mkdir -p "${release_info_dir}"

	cat > "${release_info_dir}/tag.md" <<- TAG_INFO
		${github_tag[qbittorrent]}_${github_tag[libtorrent]}
	TAG_INFO

	cat > "${release_info_dir}/title.md" <<- TITLE_INFO
		qbittorrent ${app_version[qbittorrent]} libtorrent ${app_version[libtorrent]}
	TITLE_INFO

	if _git_git ls-remote -t --exit-code "https://github.com/${qbt_revision_url}.git" "${github_tag[qbittorrent]}_${github_tag[libtorrent]}" &> /dev/null; then
		if grep -q '"name": "dependency-version.json"' < <(_curl "https://api.github.com/repos/${qbt_revision_url}/releases/tags/${github_tag[qbittorrent]}_${github_tag[libtorrent]}"); then
			until _curl "https://github.com/${qbt_revision_url}/releases/download/${github_tag[qbittorrent]}_${github_tag[libtorrent]}/dependency-version.json" > "${release_info_dir}/remote-dependency-version.json"; do
				printf '%b\n' "正在等待 dependency-version.json URL。"
				sleep 2
			done

			remote_revision_version="$(sed -rn 's|(.*)"revision": "(.*)"|\2|p' < "${release_info_dir}/remote-dependency-version.json")"
			rm -f "${release_info_dir}/remote-dependency-version.json"
			qbt_revision_version="$((remote_revision_version + 1))"
		fi
	fi

	cat > "${release_info_dir}/qt${qt_version_short_array[0]}-dependency-version.json" <<- DEPENDENCY_INFO
		{
		    "openssl": "${app_version[openssl]}",
		    "boost": "${app_version[boost]}",
		    "libtorrent_${qbt_libtorrent_version//\./_}": "${app_version[libtorrent]}",
		    "qt${qt_version_short_array[0]}": "${app_version[qtbase]}",
		    "qbittorrent": "${app_version[qbittorrent]}",
		    "revision": "${qbt_revision_version:-0}"
		}
	DEPENDENCY_INFO

	[[ ${qbt_workflow_files} == "no" && ${qbt_workflow_artifacts} == "no" ]] && source_text="source files - direct"
	[[ ${qbt_workflow_files} == "yes" ]] && source_text="source files - workflows: [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files/releases/latest)"
	[[ ${qbt_workflow_artifacts} == "yes" ]] && source_text="source files - artifacts: [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files/releases/latest)"

	cat > "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md" <<- RELEASE_INFO
		## Build info

		|           Components           |           Version           |
		| :----------------------------: | :-------------------------: |
		|          Qbittorrent           | ${app_version[qbittorrent]} |
		| Qt${qt_version_short_array[0]} |   ${app_version[qtbase]}    |
		|           Libtorrent           | ${app_version[libtorrent]}  |
		|             Boost              |    ${app_version[boost]}    |
		|            OpenSSL             |   ${app_version[openssl]}   |
		|            zlib-ng             |    ${app_version[zlib]}     |

		## Architecture and build info

		> [!NOTE]
		> ${source_text}
		>
		> These builds were created on Alpine linux using [custom prebuilt musl toolchains](https://github.com/userdocs/qbt-musl-cross-make/releases/latest) for:
	RELEASE_INFO

	{
		printf '\n%s\n' "| Crossarch | Alpine Cross 构建文件 | Arch 配置|                                                             Tuning                                                              |"
		printf '%s\n' "| :---------: | :----------------------: | :---------: | :-----------------------------------------------------------------------------------------------------------------------------: |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armel ]] && printf '%s\n' "|    armel    |    arm-linux-musleabi    |   armv5te   |                       --with-arch=armv5te --with-tune=arm926ej-s --with-float=soft --with-abi=aapcs-linux                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armhf ]] && printf '%s\n' "|    armhf    |   arm-linux-musleabihf   |   armv6zk   |              --with-arch=armv6kz --with-tune=arm1176jzf-s --with-fpu=vfpv2 --with-float=hard --with-abi=aapcs-linux             |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armv7 ]] && printf '%s\n' "|    armv7    | armv7l-linux-musleabihf  |   armv7-a   | --with-arch=armv7-a --with-tune=generic-armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-abi=aapcs-linux --with-mode=thumb |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == aarch64 ]] && printf '%s\n' "|   aarch64   |    aarch64-linux-musl    |   armv8-a   |                                               --with-arch=armv8-a --with-abi=lp64                                               |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == x86_64 ]] && printf '%s\n' "|   x86_64    |    x86_64-linux-musl     |    amd64    |                                                               N/A                                                               |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == x86 ]] && printf '%s\n' "|     x86     |     i686-linux-musl      |    i686     |                                        --with-arch=pentium-m --with-fpmath=sse --with-tune=generic --enable-cld                 |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == s390x ]] && printf '%s\n' "|    s390x    |     s390x-linux-musl     |    zEC12    |                  --with-arch=z196 --with-tune=zEC12 --with-zarch --with-long-double-128 --enable-decimal-float                  |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == powerpc ]] && printf '%s\n' "|   powerpc   |    powerpc-linux-musl    |     ppc     |                                          --enable-secureplt --enable-decimal-float=no                                           |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == ppc64el ]] && printf '%s\n' "| powerpc64le |  powerpc64le-linux-musl  |    ppc64    |                 --with-abi=elfv2 --enable-secureplt --enable-decimal-float=no --enable-targets=powerpcle-linux                  |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips ]] && printf '%s\n' "|    mips     |     mips-linux-musl      |    mips32     |                               --with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mipsel ]] && printf '%s\n' "|   mipsel    |    mipsel-linux-musl     |   mips32    |                                -with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips64 ]] && printf '%s\n' "|   mips64    |    mips64-linux-musl     |   mips64    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips64el ]] && printf '%s\n' "|  mips64el   |   mips64el-linux-musl    |   mips64    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == riscv64 ]] && printf '%s\n' "|   riscv64   |    riscv64-linux-musl    |   rv64gc    |                                 --with-arch=rv64gc --with-abi=lp64d --enable-autolink-libatomic                                 |"
		printf '\n'
	} >> "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md"

	cat >> "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md" <<- RELEASE_INFO
		## General Info

		> [!WARNING]
		> 从 Qbittorrent 4.4.0 开始，只要支持 Qt5 或发布了 qBitorrent V5，所有 cmake 构建都使用 Qt6，所有 qmake 构建都使用 Qt5。
		>
		> Qbittorrent v5 不支持 qmake (Qt5) 版本，因此 Qt6 (cmake) 将成为默认版本，并且 Qt5 版本将不再发布。
		>
		> Binary builds are stripped - See https://userdocs.github.io/qbittorrent-nox-static/#/debugging
	RELEASE_INFO

	return
}
#######################################################################################################################################################
# This is first help section that for triggers that do not require any processing and only provide a static result whe using help
#######################################################################################################################################################
while (("${#}")); do
	case ${1} in
		-b | --build-directory)
			qbt_build_dir="${2}"
			shift 2
			;;
		-bs-c | --boot-strap-cmake)
			qbt_build_tool="cmake"
			params1+=("-bs-c")
			shift
			;;
		-c | --cmake)
			qbt_build_tool="cmake"
			shift
			;;
		-d | --debug)
			qbt_build_debug="yes"
			shift
			;;
		-cd | --cache-directory)
			qbt_cache_dir="${2%/}"
			if [[ -n "${3}" && "${3}" =~ (^rm$|^bs$) ]]; then
				qbt_cache_dir_options="${3}"
				if [[ "${3}" == "rm" ]]; then
					[[ -d "${qbt_cache_dir}" ]] && rm -rf "${qbt_cache_dir}"
					printf '\n%b\n\n' " ${unicode_red_circle} 已删除缓存目录：${color_cyan_light}${qbt_cache_dir}${color_end}"
					exit
				fi
				shift 3
			elif [[ -n "${3}" && ! "${3}" =~ ^- ]]; then
				printf '\n%b\n' " ${unicode_red_circle} 仅支持 ${color_blue_light}bs${color_end} 或 ${color_blue_light}rm${color_end} 作为此开关的条件${color_end}"
				printf '\n%b\n\n' " ${unicode_yellow_circle} 有关详细信息，请参阅 ${color_blue_light}-h-cd${color_end}${color_end}"
				exit
			else
				shift 2
			fi
			;;
		-i | --icu)
			qbt_skip_icu="no"
			[[ "${qbt_skip_icu}" == "no" ]] && delete=("${delete[@]/icu/}")
			shift
			;;
		-ma | --multi-arch)
			if [[ -n "${2}" && "${multi_arch_options[${2}]}" == "${2}" ]]; then
				qbt_cross_name="${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} 使用${color_end} ${color_blue_light}-ma${color_end} 时必须提供有效的 arch 选项"
				unset "multi_arch_options[default]"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${unicode_blue_light_circle} ${arches}${color_end}"
				done
				printf '\n%b\n\n' " ${unicode_green_circle} Example usage:${color_blue_light} -ma aarch64${color_end}"
				exit 1
			fi
			;;
		-p | --proxy)
			qbt_git_proxy=("-c" "http.sslVerify=false" "-c" "http.https://github.com.proxy=${2}")
			qbt_curl_proxy=("--proxy-insecure" "-x" "${2}")
			shift 2
			;;
		-o | --optimize)
			if [[ -z ${qbt_cross_name} ]]; then
				qbt_optimize="-march=native"
				shift
			else
				printf '\n%b\n\n' " ${unicode_red_light_circle} 您不能在交叉编译中使用 ${color_blue_light}-o${color_end} 标志"
				exit 1
			fi
			;;
		-s | --strip)
			qbt_optimise_strip="yes"
			shift
			;;
		-si | --static-ish)
			if [[ -z ${qbt_cross_name} ]]; then
				qbt_static_ish="yes"
				shift
			else
				printf '\n%b\n\n' " ${unicode_red_light_circle} 您不能在交叉编译中使用 ${color_blue_light}-si${color_end} 标志${color_end}"
				exit 1
			fi
			;;
		-sdu | --script-debug-urls)
			script_debug_urls="yes"
			shift
			;;
		-wf | --workflow)
			qbt_workflow_files="yes"
			shift
			;;
		--) # end argument parsing
			shift
			break
			;;
		*) # preserve positional arguments
			params1+=("${1}")
			shift
			;;
	esac
done
# Set positional arguments in their proper place.
set -- "${params1[@]}"
#######################################################################################################################################################
# Functions part 1: Use some of our functions
#######################################################################################################################################################
_set_default_values "${@}" # see functions
_check_dependencies        # see functions
_test_url
_set_build_directory    # see functions
_set_module_urls "${@}" # see functions
_script_version         # see functions
#######################################################################################################################################################
# Environment variables - settings positional parameters of flags
#######################################################################################################################################################
[[ -n "${qbt_patches_url}" ]] && set -- -pr "${qbt_patches_url}" "${@}"
[[ -n "${qbt_boost_tag}" ]] && set -- -bt "${qbt_boost_tag}" "${@}"
[[ -n "${qbt_libtorrent_tag}" ]] && set -- -lt "${qbt_libtorrent_tag}" "${@}"
[[ -n "${qbt_qt_tag}" ]] && set -- -qtt "${qbt_qt_tag}" "${@}"
[[ -n "${qbt_qbittorrent_tag}" ]] && set -- -qt "${qbt_qbittorrent_tag}" "${@}"
#######################################################################################################################################################
# 此部分控制我们可以传递给脚本以修改某些变量和行为的标志。
#######################################################################################################################################################
while (("${#}")); do
	case "${1}" in
		-bs-p | --boot-strap-patches)
			_apply_patches bootstrap
			shift
			;;
		-bs-c | --boot-strap-cmake)
			_cmake
			shift
			;;
		-bs-r | --boot-strap-release)
			_release_info
			shift
			;;
		-bs-ma | --boot-strap-multi-arch)
			if [[ "${multi_arch_options[${qbt_cross_name}]}" == "${qbt_cross_name}" ]]; then
				_multi_arch
				shift
			else
				printf '\n%b\n\n' " ${unicode_red_circle} 使用${color_end} ${color_blue_light}-ma${color_end} 时必须提供有效的 arch 选项"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${unicode_blue_light_circle} ${arches}${color_end}"
				done
				printf '\n%b\n\n' " ${unicode_green_circle} 用法示例：${color_blue_light} -ma aarch64${color_end}"
				exit 1
			fi
			;;
		-bs-a | --boot-strap-all)
			_apply_patches bootstrap
			_release_info
			_cmake
			_multi_arch bootstrap
			shift
			;;
		-bt | --boost-version)
			if [[ -n "${2}" ]]; then
				github_tag[boost]="$(_git "${github_url[boost]}" -t "${2}")"
				app_version[boost]="${github_tag[boost]#boost-}"
				_boost_url
				qbt_workflow_override[boost]="yes"
				_test_git_ouput "${github_tag[boost]}" "boost" "${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}您必须为此开关提供标签：${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-n | --no-delete)
			qbt_skip_delete="yes"
			shift
			;;
		-m | --master)
			github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "RC_${qbt_libtorrent_version//./_}")"
			app_version[libtorrent]="${github_tag[libtorrent]}"
			qbt_workflow_override[libtorrent]="yes"
			source_default[libtorrent]="folder"
			_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "RC_${qbt_libtorrent_version//./_}"
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "master")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_default[qbittorrent]="folder"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "master"
			shift
			;;
		-lm | --libtorrent-master)
			github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "RC_${qbt_libtorrent_version//./_}")"
			app_version[libtorrent]="${github_tag[libtorrent]}"
			source_default[qbittorrent]="folder"
			qbt_workflow_override[libtorrent]="yes"
			_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "RC_${qbt_libtorrent_version//./_}"
			shift
			;;
		-lt | --libtorrent-tag)
			if [[ -n "${2}" ]]; then
				github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "$2")"
				[[ "${github_tag[libtorrent]}" =~ ^RC_ ]] && app_version[libtorrent]="${github_tag[libtorrent]/RC_/}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ "${github_tag[libtorrent]}" =~ ^libtorrent- ]] && app_version[libtorrent]="${github_tag[libtorrent]#libtorrent-}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ "${github_tag[libtorrent]}" =~ ^libtorrent_ ]] && app_version[libtorrent]="${github_tag[libtorrent]#libtorrent_}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ "${github_tag[libtorrent]}" =~ ^v[0-9] ]] && app_version[libtorrent]="${github_tag[libtorrent]#v}"
				source_archive_url[libtorrent]="https://github.com/arvidn/libtorrent/releases/download/${github_tag[libtorrent]}/libtorrent-rasterbar-${app_version[libtorrent]}.tar.gz"
				if ! _curl "${source_archive_url[libtorrent]}" &> /dev/null; then
					source_default[libtorrent]="folder"
				fi
				qbt_workflow_override[libtorrent]="yes"

				read -ra lt_version_short_array <<< "${app_version[libtorrent]//\./ }"
				qbt_libtorrent_version="${lt_version_short_array[0]}.${lt_version_short_array[1]}"
				[[ "${github_tag[libtorrent]}" =~ ^RC_ ]] && app_version[libtorrent]="RC_${app_version[libtorrent]//\./_}" # set back to RC_... so that release info has proper version context

				_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "$2"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}您必须为此开关提供标签：${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-pr | --patch-repo)
			if [[ -n "${2}" ]]; then
				if _curl "https://github.com/${2}" &> /dev/null; then
					qbt_patches_url="${2}"
				else
					printf '\n%b\n' " ${unicode_red_circle} ${color_yellow_light}此存储库不存在：${color_end}"
					printf '\n%b\n' "   ${color_cyan_light}https://github.com/${2}${color_end}"
					printf '\n%b\n\n' " ${unicode_yellow_circle} ${color_yellow_light}请提供有效的用户名和存储库。${color_end}"
					exit
				fi
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}您必须为此开关提供标签：${color_end} ${color_blue_light}${1} 用户名/存储库 ${color_end}"
				exit
			fi
			;;
		-qm | --qbittorrent-master)
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "master")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${github_tag[qbittorrent]}.tar.gz"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "master"
			shift
			;;
		-qt | --qbittorrent-tag)
			if [[ -n "${2}" ]]; then
				github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "$2")"
				app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
				if [[ "${github_tag[qbittorrent]}" =~ ^release- ]]; then
					source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/${github_tag[qbittorrent]}.tar.gz"
				else
					source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${github_tag[qbittorrent]}.tar.gz"
				fi
				qbt_workflow_override[qbittorrent]="yes"
				_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "$2"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}您必须为此开关提供标签：${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-qtt | --qt-tag)
			if [[ -n "${2}" ]]; then
				github_tag[qtbase]="$(_git "${github_url[qtbase]}" -t "${2}")"
				github_tag[qttools]="$(_git "${github_url[qttools]}" -t "${2}")"
				app_version[qtbase]="$(printf '%s' "${github_tag[qtbase]#v}" | sed 's/-lts-lgpl//g')"
				app_version[qttools]="$(printf '%s' "${github_tag[qttools]#v}" | sed 's/-lts-lgpl//g')"
				source_default[qtbase]="folder"
				source_default[qttools]="folder"
				qbt_workflow_override[qtbase]="yes"
				qbt_workflow_override[qttools]="yes"
				qbt_qt_version="${app_version[qtbase]%%.*}"
				read -ra qt_version_short_array <<< "${app_version[qtbase]//\./ }"
				qt_version_short="${qt_version_short_array[0]}.${qt_version_short_array[1]}"
				_test_git_ouput "${github_tag[qtbase]}" "qtbase" "${2}"
				_test_git_ouput "${github_tag[qttools]}" "qttools" "${2}"

				if [[ $qbt_build_tool == "cmake" && "${2}" =~ ^v5 ]]; then
					printf '\n%b\n' " ${unicode_red_circle} 请使用正确的 qt 和构建工具组合"
					printf '\n%b\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
					_print_env
					exit 1
				fi
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}您必须为此开关提供标签：${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-h | --help)
			printf '\n%b\n\n' " ${text_bold}${text_underlined}Here are a list of available options${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-b${color_end}     ${text_dim}or${color_end} ${color_blue_light}--build-directory${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-b${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-build-directory${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--boost-version${color_end}         ${color_yellow}Help:${color_end} ${color_blue_light}-h-bt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-boost-version${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-c${color_end}     ${text_dim}or${color_end} ${color_blue_light}--cmake${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-c${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-cmake${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-cd${color_end}    ${text_dim}or${color_end} ${color_blue_light}--cache-directory${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-cd${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-cache-directory${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-d${color_end}     ${text_dim}or${color_end} ${color_blue_light}--debug${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-d${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-debug${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-p${color_end}  ${text_dim}or${color_end} ${color_blue_light}--boot-strap-patches${color_end}    ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-p${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-boot-strap-patches${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-c${color_end}  ${text_dim}or${color_end} ${color_blue_light}--boot-strap-cmake${color_end}      ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-c${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-boot-strap-cmake${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-r${color_end}  ${text_dim}or${color_end} ${color_blue_light}--boot-strap-release${color_end}    ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-r${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-boot-strap-release${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-ma${color_end} ${text_dim}or${color_end} ${color_blue_light}--boot-strap-multi-arch${color_end} ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-ma${color_end} ${text_dim}or${color_end} ${color_blue_light}--help-boot-strap-multi-arch${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-a${color_end}  ${text_dim}or${color_end} ${color_blue_light}--boot-strap-all${color_end}        ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-a${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-boot-strap-all${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-i${color_end}     ${text_dim}or${color_end} ${color_blue_light}--icu${color_end}                   ${color_yellow}Help:${color_end} ${color_blue_light}-h-i${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-icu${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-lm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--libtorrent-master${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-lm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-libtorrent-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-lt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--libtorrent-tag${color_end}        ${color_yellow}Help:${color_end} ${color_blue_light}-h-lt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-libtorrent-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-m${color_end}     ${text_dim}or${color_end} ${color_blue_light}--master${color_end}                ${color_yellow}Help:${color_end} ${color_blue_light}-h-m${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-ma${color_end}    ${text_dim}or${color_end} ${color_blue_light}--multi-arch${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-ma${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-multi-arch${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-n${color_end}     ${text_dim}or${color_end} ${color_blue_light}--no-delete${color_end}             ${color_yellow}Help:${color_end} ${color_blue_light}-h-n${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-no-delete${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-o${color_end}     ${text_dim}or${color_end} ${color_blue_light}--optimize${color_end}              ${color_yellow}Help:${color_end} ${color_blue_light}-h-o${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-optimize${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-p${color_end}     ${text_dim}or${color_end} ${color_blue_light}--proxy${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-p${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-proxy${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-pr${color_end}    ${text_dim}or${color_end} ${color_blue_light}--patch-repo${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-pr${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-patch-repo${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--qbittorrent-master${color_end}    ${color_yellow}Help:${color_end} ${color_blue_light}-h-qm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-qbittorrent-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--qbittorrent-tag${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-qt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-qbittorrent-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qtt${color_end}   ${text_dim}or${color_end} ${color_blue_light}--qt-tag${color_end}                ${color_yellow}Help:${color_end} ${color_blue_light}-h-qtt${color_end}   ${text_dim}or${color_end} ${color_blue_light}--help-qtt-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-sdu${color_end}   ${text_dim}or${color_end} ${color_blue_light}--script-debug-urls${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-sdu${color_end}   ${text_dim}or${color_end} ${color_blue_light}--help-script-debug-urls${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-si${color_end}    ${text_dim}or${color_end} ${color_blue_light}--static-ish${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-strip${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--strip${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-strip${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-wf${color_end}    ${text_dim}or${color_end} ${color_blue_light}--workflow${color_end}              ${color_yellow}Help:${color_end} ${color_blue_light}-h-wf${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-workflow${color_end}"
			printf '\n%b\n' " ${text_bold}${text_underlined}Module specific help - flags are used with the modules listed here.${color_end}"
			printf '\n%b\n' " ${color_green}Use:${color_end} ${color_magenta_light}all${color_end} ${text_dim}or${color_end} ${color_magenta_light}module-name${color_end}          ${color_green}Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_magenta_light}all${color_end} ${color_blue_light}-i${color_end}"
			printf '\n%b\n' " ${text_dim}${color_magenta_light}all${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Recommended method to install all modules${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}install${color_end} ${text_dim}------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Install the ${text_dim}${color_cyan_light}${qbt_install_dir_short}/completed/qbittorrent-nox${color_end} ${text_dim}binary${color_end}"
			[[ "${os_id}" =~ ^(debian|ubuntu)$ ]] && printf '%b\n' " ${text_dim}${color_magenta_light}glibc${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build libc locally to statically link nss${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}zlib${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build zlib locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}iconv${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build iconv locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}icu${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Build ICU locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}openssl${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build openssl locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}boost${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Download, extract and build the boost library files${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}libtorrent${color_end} ${text_dim}---------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build libtorrent locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}double_conversion${color_end} ${text_dim}--${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}A cmake + Qt6 build component on modern OS only.${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qtbase${color_end} ${text_dim}-------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qtbase locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qttools${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qttools locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qbittorrent${color_end} ${text_dim}--------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qbittorrent locally${color_end}"
			printf '\n%b\n' " ${text_bold}${text_underlined}env help - supported exportable evironment variables${color_end}"
			printf '\n%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_version=\"\"${color_end} ${text_dim}--------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}1.2 - 2.0${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qt_version=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}5 - 5.15 - 6 - 6.2 - 6.3 and so on${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_build_tool=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}qmake - cmake${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_cross_name=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}x86_64 - aarch64 - armv7 - armhf${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_patches_url=\"\"${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}userdocs/qbittorrent-nox-static.${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_tag=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch for libtorrent${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qbittorrent_tag=\"\"${color_end} ${text_dim}-----------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch for qbittorrent${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_boost_tag=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch for boost${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qt_tag=\"\"${color_end} ${text_dim}--------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch for Qt${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_workflow_files=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - use qbt-workflow-files for dependencies${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_workflow_artifacts=\"\"${color_end} ${text_dim}--------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - use qbt_workflow_artifacts for dependencies${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_cache_dir=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}path empty - provide a path to a cache directory${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_master_jamfile=\"\"${color_end} ${text_dim}-${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - use RC branch instead of release jamfile${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_optimise_strip=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - strip binaries - cannot be used with debug${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_build_debug=\"\"${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - debug build - cannot be used with strip${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_standard=\"\"${color_end} ${text_dim}------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}14 - 17 - 20 - 23 - c standard for gcc - for older build combos${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_static_ish=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes no - libc linking - link dynamically to libc${color_end}"
			_print_env
			exit
			;;
		-h-b | --help-build-directory)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Default build location: ${color_cyan}${qbt_install_dir_short}${color_end}"
			printf '\n%b\n' " ${color_blue_light}-b${color_end} or ${color_blue_light}--build-directory${color_end} to set the location of the build directory."
			printf '\n%b\n' " ${color_yellow}Paths are relative to the script location. I recommend that you use a full path.${color_end}"
			printf '\n%b\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${text_dim}${color_magenta_light}all${color_end} ${text_dim}- Will install all modules and build libtorrent to the default build location${color_end}"
			printf '\n%b\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${text_dim}${color_magenta_light}module${color_end} ${text_dim}- Will install a single module to the default build location${color_end}"
			printf '\n%b\n\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${text_dim}${color_magenta_light}module${color_end} ${color_blue_light}-b${color_end} ${text_dim}${color_cyan_light}\"\$HOME/build\"${color_end} ${text_dim}- will specify a custom build directory and install a specific module use to that custom location${color_end}"
			exit
			;;
		-h-bs-p | --help-boot-strap-patches)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Creates dirs in this structure: ${color_cyan}${qbt_install_dir_short}/patches/app_name/tag/patch${color_end}"
			printf '\n%b\n' " Add your patches there, for example."
			printf '\n%b\n' " ${color_cyan}${qbt_install_dir_short}/patches/libtorrent/${app_version[libtorrent]}/patch${color_end}"
			printf '\n%b\n\n' " ${color_cyan}${qbt_install_dir_short}/patches/qbittorrent/${app_version[qbittorrent]}/patch${color_end}"
			exit
			;;
		-h-bs-c | --help-boot-cmake)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This bootstrap will install cmake and ninja build to the build directory"
			printf '\n%b\n\n'"${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs-c${color_end}"
			exit
			;;
		-h-bs-r | --help-boot-strap-release)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' "${color_red_light} Github action specific. You probably dont need it${color_end}"
			printf '\n%b\n' " This switch creates some github release template files in this directory"
			printf '\n%b\n' " ${qbt_install_dir_short}/release_info"
			printf '\n%b\n\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs-r${color_end}"
			exit
			;;
		-h-bs-ma | --help-boot-strap-multi-arch)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} Github action and Alpine specific. You probably dont need it${color_end}"
			printf '\n%b\n' " This switch bootstraps the musl cross build files needed for any provided and supported architecture"
			printf '\n%b\n' " ${unicode_yellow_circle} armhf"
			printf '%b\n' " ${unicode_yellow_circle} armv7"
			printf '%b\n' " ${unicode_yellow_circle} aarch64"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs-ma ${qbt_cross_name:-aarch64}${color_end}"
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can also set it as a variable to trigger cross building: ${color_blue_light}export qbt_cross_name=${qbt_cross_name:-aarch64}${color_end}"
			exit
			;;
		-h-bs-a | --help-boot-strap-all)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} Github action specific and Alpine only. You probably dont need it${color_end}"
			printf '\n%b\n' " Performs all bootstrapping options"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs-a${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Patches${color_end}"
			printf '%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Release info${color_end}"
			printf '%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Cmake and ninja build${color_end} if the ${color_blue_light}-c${color_end} flag is passed"
			printf '%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Multi arch${color_end} if the ${color_blue_light}-ma${color_end} flag is passed"
			printf '\n%b\n' " Equivalent of doing: ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs -bs-r${color_end}"
			printf '\n%b\n\n' " And with ${color_blue_light}-c${color_end} and ${color_blue_light}-ma${color_end} : ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs -bs-c -bs-ma -bs-r ${color_end}"
			exit
			;;
		-h-bt | --help-boost-version)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This will let you set a specific version of boost to use with older build combos"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-bt boost-1.81.0${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-bt boost-1.82.0.beta1${color_end}"
			exit
			;;
		-h-c | --help-cmake)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This flag can change the build process in a few ways."
			printf '\n%b\n' " ${unicode_yellow_circle} Use cmake to build libtorrent."
			printf '%b\n' " ${unicode_yellow_circle} Use cmake to build qbittorrent."
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can use this flag with ICU and qtbase will use ICU instead of iconv."
			exit
			;;
		-h-cd | --help-cache-directory)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This will let you set a path of a directory that contains cached github repos of modules"
			printf '\n%b\n' " ${unicode_yellow_circle} Cached apps folder names must match the module name. Case and spelling"
			printf '\n%b\n' " For example: ${color_cyan_light}~/cache_dir/qbittorrent${color_end}"
			printf '\n%b\n' " Additonal flags supported: ${color_cyan_light}rm${color_end} - remove the cache directory and exit"
			printf '\n%b\n' " Additonal flags supported: ${color_cyan_light}bs${color_end} - download cache for all activated modules then exit"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir${color_end}"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir rm${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir bs${color_end}"
			exit
			;;
		-h-d | --help-debug)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n\n' " Enables debug symbols for libtorrent and qbitorrent when building - required for gdb backtrace"
			exit
			;;
		-h-n | --help-no-delete)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Skip all delete functions for selected modules to leave source code directories behind."
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-n${color_end}"
			exit
			;;
		-h-i | --help-icu)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Use ICU libraries when building qBittorrent. Final binary size will be around ~50Mb"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-i${color_end}"
			exit
			;;
		-h-m | --help-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}libtorrent RC_${qbt_libtorrent_version//./_}${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}qBittorrent"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-lm${color_end}"
			exit
			;;
		-h-ma | --help-multi-arch)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} Github action and Alpine specific. You probably dont need it${color_end}"
			printf '\n%b\n' " This switch will make the script use the cross build configuration for these supported architectures"
			printf '\n%b\n' " ${unicode_yellow_circle} armhf"
			printf '%b\n' " ${unicode_yellow_circle} armv7"
			printf '%b\n' " ${unicode_yellow_circle} aarch64"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/$(basename -- "$0")${color_end} ${color_blue_light}-bs-ma ${qbt_cross_name:-aarch64}${color_end}"
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can also set it as a variable to trigger cross building: ${color_blue_light}export qbt_cross_name=${qbt_cross_name:-aarch64}${color_end}"
			exit
			;;
		-h-lm | --help-libtorrent-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}libtorrent-${qbt_libtorrent_version}${color_end}"
			printf '\n%b\n' " This master that will be used is: ${color_green}RC_${qbt_libtorrent_version//./_}${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-lm${color_end}"
			exit
			;;
		-h-lt | --help-libtorrent-tag)
			if [[ ! "${github_tag[libtorrent]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided libtorrent tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end}${color_blue_light} -lt ${color_cyan_light}${github_tag[libtorrent]}${color_end} ${color_blue_light}-h-lt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-lt${color_end} ${color_cyan_light}${github_tag[libtorrent]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-o | --help-optimize)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Warning:${color_end} using this flag will mean your static build is limited a CPU that matches the host spec"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-o${color_end}"
			printf '\n%b\n\n' " Additonal flags used: ${color_cyan_light}-march=native${color_end}"
			exit
			;;
		-h-p | --help-proxy)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Specify a proxy URL and PORT to use with curl and git"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage examples:"
			printf '\n%b\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}username:password@https://123.456.789.321:8443${color_end}"
			printf '\n%b\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}https://proxy.com:12345${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} Call this before the help option to see outcome dynamically:"
			printf '\n%b\n\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}https://proxy.com:12345${color_end} ${color_blue_light}-h-p${color_end}"
			[[ -n "${qbt_curl_proxy[*]}" ]] && printf '%b\n' " proxy command: ${color_cyan_light}${qbt_curl_proxy[*]}${text_newline}${color_end}"
			exit
			;;
		-h-pr | --help-patch-repo)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Specify a username and repo to use patches hosted on github${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}There is a specific github directory format you need to use with this flag${color_end}"
			printf '\n%b\n' " ${color_cyan_light}patches/libtorrent/${app_version[libtorrent]}/patch${color_end}"
			printf '%b\n' " ${color_cyan_light}patches/libtorrent/${app_version[libtorrent]}/Jamfile${color_end} ${color_red_light}(defaults to branch master)${color_end}"
			printf '\n%b\n' " ${color_cyan_light}patches/qbittorrent/${app_version[qbittorrent]}/patch${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}If an installation tag matches a hosted tag patch file, it will be automatically used.${color_end}"
			printf '\n%b\n' " The tag name will alway be an abbreviated version of the default or specificed tag.${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} ${color_green}Usage example:${color_end} ${color_blue_light}-pr usnerame/repo${color_end}"
			exit
			;;
		-h-qm | --help-qbittorrent-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}qBittorrent${color_end}"
			printf '\n%b\n' " This master that will be used is: ${color_green}master${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-qm${color_end}"
			exit
			;;
		-h-qt | --help-qbittorrent-tag)
			if [[ ! "${github_tag[qbittorrent]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided qBittorrent tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end}${color_blue_light} -qt ${color_cyan_light}${github_tag[qbittorrent]}${color_end} ${color_blue_light}-h-qt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-qt${color_end} ${color_cyan_light}${github_tag[qbittorrent]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-qtt | --help-qt-tag)
			if [[ ! "${github_tag[qtbase]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided Qt tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/$(basename -- "$0")${color_end}${color_blue_light} -qt ${color_cyan_light}${github_tag[qtbase]}${color_end} ${color_blue_light}-h-qt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-qt${color_end} ${color_cyan_light}${github_tag[qtbase]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-s | --help-strip)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Strip the qbittorrent-nox binary of unneeded symbols to decrease file size"
			printf '\n%b\n' " ${unicode_yellow_circle} Static musl builds don't work with qBittorrents built in stacktrace."
			printf '\n%b\n' " If you need to debug a build with gdb you must build a debug build using the flag ${color_blue_light}-d${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-s${color_end}"
			exit
			;;
		-h-si | --help-static-ish)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Do not statically link libc (glibc/muslc) when building qbittorrent-nox"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-si${color_end}"
			exit
			;;
		-h-sdu | --help-script-debug-urls)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_blue_light_circle} This will print out all the ${color_yellow_light}_set_module_urls${color_end} array info to check"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-sdu${color_end}"
			exit
			;;
		-h-wf | --help-workflow)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} Use archives from ${color_cyan_light}https://github.com/userdocs/qbt-workflow-files/releases/latest${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Warning:${color_end} If you set a custom version for supported modules it will override and disable workflows as a source for that module"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-wf${color_end}"
			exit
			;;
		--) # end argument parsing
			shift
			break
			;;
		-*) # unsupported flags
			printf '\n%b\n\n' " ${unicode_red_circle} Error: Unsupported flag ${color_red_light}${1}${color_end} - use ${color_green_light}-h${color_end} or ${color_green_light}--help${color_end} to see the valid options${color_end}" >&2
			exit 1
			;;
		*) # preserve positional arguments
			params2+=("${1}")
			shift
			;;
	esac
done
set -- "${params2[@]}" # 将位置参数设置在适当的位置。
#######################################################################################################################################################
# Functions part 2: Use some of our functions
#######################################################################################################################################################
[[ "${1}" == "install" ]] && _install_qbittorrent "${@}" # 查看函数
#######################################################################################################################################################
# 如果我们发现任何 github 标签验证失败或者 url 无效，我们现在就来看看
#######################################################################################################################################################
_error_tag
#######################################################################################################################################################
# 函数第 3 部分：任何要求上述 while 循环选项中的参数已移动的函数都必须位于此行之后
#######################################################################################################################################################
_set_cxx_standard
_set_build_cons
_debug "${@}"                # 需要从选项块 2 转移参数
_installation_modules "${@}" # 需要从选项块 2 转移参数
#######################################################################################################################################################
# 如果任何模块未通过 qbt_modules_test，则立即退出。
#######################################################################################################################################################
if [[ "${qbt_modules_test}" == 'fail' || "${#}" -eq '0' ]]; then
	printf '\n%b\n' " ${text_blink}${unicode_red_circle}${color_end}${text_bold} 不支持一个或多个提供的模块${color_end}"
	printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} 下面是编译的模块列表${color_end}"
	printf '\n%b\n' " ${unicode_magenta_circle}${color_magenta_light} ${qbt_modules[*]}${color_end}"
	_print_env
	exit
fi
#######################################################################################################################################################
# Functions part 4:
#######################################################################################################################################################
_cmake
_multi_arch
#######################################################################################################################################################
# shellcheck disable=SC2317
_glibc_bootstrap() {
	sub_dir="/BUILD"
}
# shellcheck disable=SC2317
_glibc() {
	CFLAGS="-O2 -U_FORTIFY_SOURCE" "${qbt_dl_folder_path}/configure" "${multi_glibc[@]}" --prefix="${qbt_install_dir}" --enable-static-nss --disable-nscd --srcdir="${qbt_dl_folder_path}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	CFLAGS="-O2 -U_FORTIFY_SOURCE" make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/$app_name.log"
	_post_command build
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"

	unset sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_zlib() {
	if [[ "${qbt_build_tool}" == "cmake" ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		# force set some ARCH when using zlib-ng, cmake and musl-cross since it does not detect the arch correctly on Alpine.
		[[ "${qbt_cross_target}" =~ ^(alpine)$ ]] && printf '%b\n' "\narchfound ${qbt_zlib_arch:-$(apk --print-arch)}" >> "${qbt_dl_folder_path}/cmake/detect-arch.c"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D ZLIB_COMPAT=ON \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		# force set some ARCH when using zlib-ng, configure and musl-cross since it does not detect the arch correctly on Alpine.
		[[ "${qbt_cross_target}" =~ ^(alpine)$ ]] && sed "s|  CFLAGS=\"-O2 \${CFLAGS}\"|  ARCH=${qbt_zlib_arch:-$(apk --print-arch)}\n  CFLAGS=\"-O2 \${CFLAGS}\"|g" -i "${qbt_dl_folder_path}/configure"
		./configure --prefix="${qbt_install_dir}" --static --zlib-compat |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_iconv() {
	if [[ -n "${qbt_cache_dir}" && -d "${qbt_cache_dir}/${app_name}" ]]; then
		./gitsub.sh pull --depth 1
		./autogen.sh
	fi

	./configure "${multi_iconv[@]}" --prefix="${qbt_install_dir}" --disable-shared --enable-static CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_icu_bootstrap() {
	if [[ -n "${qbt_cache_dir}" && -d "${qbt_cache_dir}/${app_name}" && "${qbt_workflow_files}" == "no" ]]; then
		sub_dir="/icu4c/source"
	else
		sub_dir="/source"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_icu() {
	if [[ "${multi_arch_options[${qbt_cross_name:-default}]}" == "${qbt_cross_name}" ]]; then
		mkdir -p "${qbt_install_dir}/${app_name}/cross"
		_pushd "${qbt_install_dir}/${app_name}/cross"
		"${qbt_install_dir}/${app_name}${sub_dir}/runConfigureICU" Linux/gcc
		make -j"$(nproc)"
		_pushd "${qbt_install_dir}/${app_name}${sub_dir}"
	fi

	./configure "${multi_icu[@]}" --prefix="${qbt_install_dir}" --disable-shared --enable-static --disable-samples --disable-tests --with-data-packaging=static CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"

	unset sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_openssl() {
	"${multi_openssl[@]}" --prefix="${qbt_install_dir}" --libdir="${lib_dir##*/}" --openssldir="/etc/ssl" threads no-shared no-dso no-comp CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	make install_sw |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_boost_bootstrap() {
	# If using source files and jfrog fails, default to git, if we are not using workflows sources.
	if [[ "${boost_url_status}" =~ (403|404) && "${qbt_workflow_files}" == "no" && "${qbt_workflow_artifacts}" == "no" ]]; then
		source_default["${app_name}"]="folder"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_boost() {
	if [[ "${source_default["${app_name}"]}" == "file" ]]; then
		mv -f "${qbt_dl_folder_path}/" "${qbt_install_dir}/boost"
		_pushd "${qbt_install_dir}/boost"
	fi

	if [[ "${qbt_build_tool}" != 'cmake' ]]; then
		"${qbt_install_dir}/boost/bootstrap.sh" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		ln -s "${qbt_install_dir}/boost/boost" "${qbt_install_dir}/boost/include"
	else
		printf '%b\n' " ${unicode_yellow_circle} 跳过 b2，因为我们在 Qt6 中使用 cmake"
	fi

	if [[ "${source_default["${app_name}"]}" == "folder" ]]; then
		"${qbt_install_dir}/boost/b2" headers |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_libtorrent() {
	export BOOST_ROOT="${qbt_install_dir}/boost"
	export BOOST_INCLUDEDIR="${qbt_install_dir}/boost"
	export BOOST_BUILD_PATH="${qbt_install_dir}/boost"

	if [[ "${qbt_build_tool}" == 'cmake' ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_libtorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="Release" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir};${qbt_install_dir}/boost" \
			-D Boost_NO_BOOST_CMAKE=TRUE \
			-D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D Iconv_LIBRARY="${lib_dir}/libiconv.a" \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		[[ ${qbt_cross_name} =~ ^(armhf|armv7)$ ]] && arm_libatomic="-l:libatomic.a"
		# Check the actual version of the cloned libtorrent instead of using the tag so that we can determine RC_1_1, RC_1_2 or RC_2_0 when a custom pr branch was used. This will always give an accurate result.
		libtorrent_version_hpp="$(sed -rn 's|(.*)LIBTORRENT_VERSION "(.*)"|\2|p' include/libtorrent/version.hpp)"
		if [[ "${libtorrent_version_hpp}" =~ ^1\.1\. ]]; then
			libtorrent_library_filename="libtorrent.a"
		else
			libtorrent_library_filename="libtorrent-rasterbar.a"
		fi

		if [[ "${libtorrent_version_hpp}" =~ ^2\. ]]; then
			lt_version_options=()
			libtorrent_libs="-l:libboost_system.a -l:${libtorrent_library_filename} -l:libtry_signal.a ${arm_libatomic}"
			lt_cmake_flags="-DTORRENT_USE_LIBCRYPTO -DTORRENT_USE_OPENSSL -DTORRENT_USE_I2P=1 -DBOOST_ALL_NO_LIB -DBOOST_ASIO_ENABLE_CANCELIO -DBOOST_ASIO_HAS_STD_CHRONO -DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_SYSTEM_STATIC_LINK=1 -DTORRENT_SSL_PEERS -DBOOST_ASIO_NO_DEPRECATED"
		else
			lt_version_options=("iconv=on")
			libtorrent_libs="-l:libboost_system.a -l:${libtorrent_library_filename} ${arm_libatomic} -l:libiconv.a"
			lt_cmake_flags="-DTORRENT_USE_LIBCRYPTO -DTORRENT_USE_OPENSSL -DTORRENT_USE_I2P=1 -DBOOST_ALL_NO_LIB -DBOOST_ASIO_ENABLE_CANCELIO -DBOOST_ASIO_HAS_STD_CHRONO -DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_SYSTEM_STATIC_LINK=1 -DTORRENT_USE_ICONV=1"
		fi

		"${qbt_install_dir}/boost/b2" "${multi_libtorrent[@]}" -j"$(nproc)" "${lt_version_options[@]}" address-model="${bitness:-$(getconf LONG_BIT)}" "${qbt_libtorrent_debug}" optimization=speed cxxstd="${qbt_standard}" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static cxxflags="${CXXFLAGS}" cflags="${CPPFLAGS}" linkflags="${LDFLAGS}" install --prefix="${qbt_install_dir}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		libtorrent_strings_version="$(strings -d "${lib_dir}/${libtorrent_library_filename}" | grep -Eom1 "^libtorrent/[0-9]\.(.*)")" # ${libtorrent_strings_version#*/}
		cat > "${PKG_CONFIG_PATH}/libtorrent-rasterbar.pc" <<- LIBTORRENT_PKG_CONFIG
			prefix=${qbt_install_dir}
			libdir=\${prefix}/lib
			includedir=\${prefix}/include

			Name: libtorrent-rasterbar
			Description: The libtorrent-rasterbar libraries
			Version: ${libtorrent_strings_version#*/}

			Requires:
			Libs: -L\${libdir} ${libtorrent_libs}
			Cflags: -I\${includedir} -I${BOOST_ROOT} ${lt_cmake_flags}
		LIBTORRENT_PKG_CONFIG
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_double_conversion() {
	if [[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_double_conversion[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
			-D CMAKE_INSTALL_LIBDIR=lib \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_qtbase() {

	cat > "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS
		MAKEFILE_GENERATOR      = UNIX
		CONFIG                 += incremental
		QMAKE_INCREMENTAL_STYLE = sublib

		include(../common/linux.conf)
	QT_MKSPECS

	if [[ "${qbt_cross_name}" =~ ^(x86|x86_64)$ ]]; then
		cat >> "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS

			QMAKE_CFLAGS            = -m${bitness:-$(getconf LONG_BIT)}
			QMAKE_LFLAGS            = -m${bitness:-$(getconf LONG_BIT)}

		QT_MKSPECS
	fi

	cat >> "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS
		include(../common/gcc-base-unix.conf)
		include(../common/g++-unix.conf)

		# modifications to g++.conf
		QMAKE_CC                = ${qbt_cross_host}-gcc
		QMAKE_CXX               = ${qbt_cross_host}-g++
		QMAKE_LINK              = ${qbt_cross_host}-g++
		QMAKE_LINK_SHLIB        = ${qbt_cross_host}-g++

		# modifications to linux.conf
		QMAKE_AR                = ${qbt_cross_host}-ar cqs
		QMAKE_OBJCOPY           = ${qbt_cross_host}-objcopy
		QMAKE_NM                = ${qbt_cross_host}-nm -P
		QMAKE_STRIP             = ${qbt_cross_host}-strip

		load(qt_config)
	QT_MKSPECS

	if [[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_libtorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="release" \
			-D QT_FEATURE_optimize_full=on -D QT_FEATURE_static=on -D QT_FEATURE_shared=off \
			-D QT_FEATURE_gui=off -D QT_FEATURE_openssl_linked=on -D QT_FEATURE_dbus=off \
			-D QT_FEATURE_system_pcre2=off -D QT_FEATURE_widgets=off \
			-D FEATURE_androiddeployqt=OFF -D FEATURE_animation=OFF \
			-D QT_FEATURE_testlib=off -D QT_BUILD_EXAMPLES=off -D QT_BUILD_TESTS=off \
			-D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF -D QT_BUILD_TESTS_BY_DEFAULT=OFF \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	elif [[ "${qbt_qt_version}" =~ ^5 ]]; then
		if [[ "${qbt_skip_icu}" == "no" ]]; then
			icu=("-icu" "-no-iconv" "QMAKE_CXXFLAGS=-w -fpermissive")
		else
			icu=("-no-icu" "-iconv" "QMAKE_CXXFLAGS=-w -fpermissive")
		fi
		# Fix 5.15.4 to build on gcc 11
		sed '/^#  include <utility>/a #  include <limits>' -i "src/corelib/global/qglobal.h"
		# Don't strip by default by disabling these options. We will set it as off by default and use it with a switch
		printf '%b\n' "CONFIG                 += ${qbt_strip_qmake}" >> "mkspecs/common/linux.conf"
		./configure "${multi_qtbase[@]}" -prefix "${qbt_install_dir}" "${icu[@]}" -opensource -confirm-license -release \
			-openssl-linked -static -c++std "${qbt_cxx_standard}" -qt-pcre \
			-no-feature-glib -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples \
			-skip tests -nomake tests -skip examples -nomake examples \
			-I "${include_dir}" -L "${lib_dir}" QMAKE_LFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${unicode_red_circle} 请使用正确的 qt 和构建工具组合"
		printf '\n%b\n\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
		exit 1
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_qttools() {
	if [[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_libtorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="release" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	elif [[ "${qbt_qt_version}" =~ ^5 ]]; then
		"${qbt_install_dir}/bin/qmake" -set prefix "${qbt_install_dir}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		"${qbt_install_dir}/bin/qmake" QMAKE_CXXFLAGS="-std=${qbt_cxx_standard} -static -w -fpermissive" QMAKE_LFLAGS="-static" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${unicode_red_circle} 请使用正确的 qt 和构建工具组合"
		printf '\n%b\n\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
		exit 1
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317
_qbittorrent() {
	[[ "${os_id}" =~ ^(alpine)$ ]] && stacktrace="OFF"

	if [[ "${qbt_build_tool}" == 'cmake' ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_qbittorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="release" \
			-D QT6="${qbt_use_qt6}" \
			-D STACKTRACE="${stacktrace:-ON}" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir};${qbt_install_dir}/boost" \
			-D Boost_NO_BOOST_CMAKE=TRUE \
			-D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
			-D Iconv_LIBRARY="${lib_dir}/libiconv.a" \
			-D GUI=OFF \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		./bootstrap.sh |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		./configure \
			QT_QMAKE="${qbt_install_dir}/bin" \
			--prefix="${qbt_install_dir}" \
			"${multi_qbittorrent[@]}" \
			"${qbt_qbittorrent_debug}" \
			--disable-gui \
			CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" \
			--with-boost="${qbt_install_dir}/boost" --with-boost-libdir="${lib_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi

	[[ -f "${qbt_install_dir}/bin/qbittorrent-nox" ]] && cp -vf "${qbt_install_dir}/bin/qbittorrent-nox" "${qbt_install_dir}/completed/qbittorrent-nox"
}
#######################################################################################################################################################
# 模块安装程序循环。这将循环激活的模块并通过其相应的功能安装它们
#######################################################################################################################################################
for app_name in "${qbt_modules[@]}"; do
	if [[ "${qbt_cache_dir_options}" != "bs" ]] && [[ ! -d "${qbt_install_dir}/boost" && "${app_name}" =~ (libtorrent|qbittorrent) ]]; then
		printf '\n%b\n\n' " ${unicode_red_circle}${color_red_light} 警告${color_end} 该模块依赖于 boost 模块。将它们一起使用：${color_magenta_light}boost ${app_name}${color_end} "
	else
		if [[ "${skip_modules["${app_name}"]}" == "no" ]]; then
			############################################################
			skipped_false=$((skipped_false + 1))
			############################################################
			if command -v "_${app_name}_bootstrap" &> /dev/null; then
				"_${app_name}_bootstrap"
			fi
			########################################################
			if [[ "${app_name}" =~ (glibc|iconv|icu) ]]; then
				_custom_flags_reset
			else
				_custom_flags_set
			fi
			############################################################
			_download
			############################################################
			[[ "${qbt_cache_dir_options}" == "bs" && "${skipped_false}" -eq "${#qbt_modules[@]}" ]] && printf '\n'
			[[ "${qbt_cache_dir_options}" == "bs" ]] && continue
			############################################################
			_apply_patches
			############################################################
			"_${app_name}"
			############################################################
			_fix_static_links
			[[ "${app_name}" != "boost" ]] && _delete_function
			[[ -f "${qbt_install_dir}/logs/${app_name}.log" ]] && cp -vf "${qbt_install_dir}/logs/${app_name}.log" "${release_info_dir}/"
			# [[ "${app_name}" == "qbittorrent" ]] && \
			# find "${release_info_dir}" -maxdepth 1 -type f -exec mv -v {} "${qbt_install_dir}/completed/" \;
		fi

		if [[ "${#qbt_modules_skipped[@]}" -gt '0' ]]; then
			printf '\n%b' " ${unicode_magenta_light_circle} 当前的任务进度:"
			for skipped_true in "${qbt_modules_skipped[@]}"; do
				printf '%b' " ${color_cyan_light}${skipped_true}${color_end}"
			done
			printf '\n'
		fi

		[[ "${skipped_false}" -eq "${#qbt_modules[@]}" ]] && printf '\n'
	fi
	_pushd "${qbt_working_dir}"
done
#######################################################################################################################################################
# We are all done so now exit
#######################################################################################################################################################
exit
