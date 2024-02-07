#!/usr/bin/env bash
# cSpell:includeRegExp #.*
# Copyright 2020 by userdocs and contributors
# SPDX-License-Identifier: Apache-2.0
# @author - userdocs
# @contributors IceCodeNew Stanislas boredazfcuk AdvenT. guillaumedsde inochisa
# @credits - https://gist.github.com/notsure2 https://github.com/c0re100/qBittorrent-Enhanced-Edition
# Script Formatting - https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format

# 脚本版本 = 主要次要补丁
script_version="2.0.0"

# 设置一些脚本功能 - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -a

# 取消设置一些变量以设置默认值。
unset qbt_skip_delete qbt_git_proxy qbt_curl_proxy qbt_install_dir qbt_build_dir qbt_working_dir qbt_modules_test qbt_python_version

# Color me up Scotty - 定义一些颜色值以用作脚本中的变量。
cr="\e[31m" clr="\e[91m"                             # [c]olor[r]ed     [c]olor[l]ight[r]ed
cg="\e[32m" clg="\e[92m"                             # [c]olor[g]reen   [c]olor[l]ight[g]reen
cy="\e[33m" cly="\e[93m"                             # [c]olor[y]ellow  [c]olor[l]ight[y]ellow
cb="\e[34m" clb="\e[94m"                             # [c]olor[b]lue    [c]olor[l]ight[b]lue
cm="\e[35m" clm="\e[95m"                             # [c]olor[m]agenta [c]olor[l]ight[m]agenta
cc="\e[36m" clc="\e[96m"                             # [c]olor[c]yan    [c]olor[l]ight[c]yan
tb="\e[1m" td="\e[2m" tu="\e[4m" tn="\n" tbk="\e[5m" # [t]ext[b]old [t]ext[d]im [t]ext[u]nderlined [t]ext[n]ewline [t]ext[b]lin[k]
urc="\e[31m\U2B24\e[0m" ulrc="\e[91m\U2B24\e[0m"     # [u]nicode[r]ed[c]ircle     [u]nicode[l]ight[r]ed[c]ircle
ugc="\e[32m\U2B24\e[0m" ulgc="\e[92m\U2B24\e[0m"     # [u]nicode[g]reen[c]ircle   [u]nicode[l]ight[g]reen[c]ircle
uyc="\e[33m\U2B24\e[0m" ulyc="\e[93m\U2B24\e[0m"     # [u]nicode[y]ellow[c]ircle  [u]nicode[l]ight[y]ellow[c]ircle
ubc="\e[34m\U2B24\e[0m" ulbc="\e[94m\U2B24\e[0m"     # [u]nicode[b]lue[c]ircle    [u]nicode[l]ight[b]lue[c]ircle
umc="\e[35m\U2B24\e[0m" ulmc="\e[95m\U2B24\e[0m"     # [u]nicode[m]agenta[c]ircle [u]nicode[l]ight[m]agenta[c]ircle
ucc="\e[36m\U2B24\e[0m" ulcc="\e[96m\U2B24\e[0m"     # [u]nicode[c]yan[c]ircle    [u]nicode[l]ight[c]yan[c]ircle
ugrc="\e[37m\U2B24\e[0m" ulgrcc="\e[97m\U2B24\e[0m"  # [u]nicode[gr]ey[c]ircle    [u]nicode[l]ight[gr]ey[c]ircle
cend="\e[0m"

_color_test() {
	colour_array=("${cr}red" "${clr}light red" "${cg}green" "${clg}light green" "${cy}yellow" "${cly}light yellow" "${cb}blue" "${clb}ligh blue" "${cm}magenta" "${clm}light magenta" "${cc}cyan" "${clc}light cyan")
	formatting_array=("${tb}Text Bold" "${td}Text Dim" "${tu}Text Undelrine" "${tn}New line" "${tbk}Text Blink")
	unicode_array=("${urc}" "${ulrc}" "${ugc}" "${ulgc}" "${uyc}" "${ulyc}" "${ubc}" "${ulbc}" "${umc}" "${ulmc}" "${ucc}" "${ulcc}" "${ugrc}" "${ulgrcc}")
	printf '\n'
	for colours in "${colour_array[@]}" "${formatting_array[@]}" "${unicode_array[@]}"; do
		printf '%b\n' "${colours}${cend}"
	done
	printf '\n'
	exit
}
[[ "${1}" == "ctest" ]] && _color_test

# 检查我们是否在受支持的操作系统和版本上。
# 获取主要平台名称，例如：debian、ubuntu 或 alpine
# shellcheck source=/dev/null
what_id="$(source /etc/os-release && printf "%s" "${ID}")"

# 获取此操作系统的代号。请注意，Alpine 没有唯一的代号。
# shellcheck source=/dev/null
what_version_codename="$(source /etc/os-release && printf "%s" "${VERSION_CODENAME}")"

# 获取此代号的版本号，例如：10、20.04、3.12.4
# shellcheck source=/dev/null
what_version_id="$(source /etc/os-release && printf "%s" "${VERSION_ID%_*}")"

# 考虑版本控制 3.1 或 3.1.0 中的变化以确保检查工作正常
[[ "$(wc -w <<< "${what_version_id//\./ }")" -eq "2" ]] && alpline_min_version="310"

# If alpine, set the codename to alpine. We check for min v3.10 later with codenames.
if [[ "${what_id}" =~ ^(alpine)$ ]]; then
	what_version_codename="alpine"
fi

## Check against allowed codenames or if the codename is alpine version greater than 3.10
if [[ ! "${what_version_codename}" =~ ^(alpine|bullseye|focal|jammy)$ ]] || [[ "${what_version_codename}" =~ ^(alpine)$ && "${what_version_id//\./}" -lt "${alpline_min_version:-3100}" ]]; then
	printf '\n%b\n\n' " ${urc} ${cy} 这不是受支持的操作系统。没有理由继续下去。${cend}"
	printf '%b\n\n' " id: ${td}${cly}${what_id}${cend} codename: ${td}${cly}${what_version_codename}${cend} version: ${td}${clr}${what_version_id}${cend}"
	printf '%b\n' " ${uyc} ${td}以下是支持的平台${cend}"
	printf '%b\n' " ${clm}Debian${cend} - ${clb}bullseye${cend}"
	printf '%b\n' " ${clm}Ubuntu${cend} - ${clb}focal${cend} - ${clb}jammy${cend}"
	printf '%b\n\n' " ${clm}Alpine${cend} - ${clb}3.10.0${cend} or greater"
	exit 1
fi

# 如果文件存在，则从文件获取环境变量，但它将被传递给脚本的开关和标志覆盖
# shellcheck source=/dev/null
if [[ -f "${PWD}/.qbt_env" ]]; then
	printf '\n%b\n' " ${umc} Sourcing .qbt_env file"
	source "${PWD}/.qbt_env"
fi

# Multi arch stuff
# 从这里定义我们使用的所有可用的 multi arches https://github.com/userdocs/qbt-musl-cross-make#readme
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

# 此函数设置了一些我们使用的默认值，但在运行脚本之前，其值可以被某些标志覆盖或导出为变量
_set_default_values() {
	# 对于 docker deploys 不提示设置时区。
	export DEBIAN_FRONTEND="noninteractive"
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo "Asia/Shanghai" > /etc/timezone

	qBittorrent_version="${qBittorrent_version:-qbittorrent}"

	# 默认编译配置是qmake + qt5, qbt_build_tool=cmake or -c 会让qt6和cmake默认
	qbt_build_tool="${qbt_build_tool:-qmake}"

	# 默认为空以使用主机本地编译工具。这样我们就可以在受支持的操作系统上编译原生架构并跳过交叉编译工具链
	qbt_cross_name="${qbt_cross_name:-default}"

	# Default to host - 除了它的默认值，我们并没有真正使用它来做任何事情，所以不需要设置它。
	qbt_cross_target="${qbt_cross_target:-${what_id}}"

	# 是创建调试版本以与 gdb 一起使用 - 禁用剥离- 由于某些原因，libtorrent b2 编译为 200MB 或更大。 qbt_build_debug=yes 或 -d
	qbt_build_debug="${qbt_build_debug:-no}"

	# github actions workflows - 使用 https://github.com/userdocs/qbt-workflow-files/releases/latest 而不是直接从各种源位置下载。
	# 提供替代源并且在编译矩阵编译时不会垃圾邮件下载主机。
	qbt_workflow_files="${qbt_workflow_files:-no}"

	# github actions workflows - 使用保存为工件的工作流文件，而不是从每个矩阵的工作流文件或主机下载
	qbt_workflow_artifacts="${qbt_workflow_artifacts:-no}"

	# 以这种格式提供一个 git 用户名和 repo - username/repo
	# 在这个 repo 中，结构需要像这样 /patches/libtorrent/1.2.11/patch 和/或 /patches/qbittorrent/4.3.1/patch
	# 你的补丁文件将自动获取并加载那些匹配的标签。
	qbt_patches_url="${qbt_patches_url:-hong0980/qbittorrent-nox-static}"

	# 默认此版本的 libtorrent 没有指定标签或分支。 qbt_libtorrent_version=1.2 或 -lt v1.2.18
	qbt_libtorrent_version="${qbt_libtorrent_version:-2.0}"

	# 除非我们需要相关 RC 分支的特定修复，否则使用 release Jamfile。
	# 当存在需要自定义 jamfile 的非向后移植更改时，使用它也可以中断编译
	qbt_libtorrent_master_jamfile="${qbt_libtorrent_master_jamfile:-no}"

	# 默认情况下剥离符号，因为我们需要完整的调试版本才能对 gdb 进行回溯有用，因此剥离是一种明智的默认优化。
	qbt_optimise_strip="${qbt_optimise_strip:-yes}"

	# Github 操作特定 - 编译修订 - 工作流将动态设置它，以便 url 不会硬编码到单个 repo
	qbt_revision_url="${qbt_revision_url:-hong0980/qbittorrent-nox-static}"

	# 提供一个路径来检查缓存的本地 git repos 并使用它们。优先于工作流程文件。
	qbt_cache_dir="${qbt_cache_dir%/}"

	# icu 标签的环境设置
	qbt_skip_icu="${qbt_skip_icu:-no}"

	# 我们只使用 python3，但如果我们出于某种原因需要更改它会更容易。
	qbt_python_version="3"

	# 设置用于编译 cxx 代码的 CXX 标准。
	# ${standard} - 设置 CXX 标准。您可能需要为某些应用程序的旧版本设置 c++14，例如 qt 5.12
	standard="17" cxx_standard="c++${standard}"

	# 我们用于包源的 Alpine 存储库
	CDN_URL="http://dl-cdn.alpinelinux.org/alpine/edge/main" # for alpine

	# 在数组中定义可用模块列表。
	qbt_modules=("all" "install" "glibc" "zlib" "iconv" "icu" "openssl" "boost" "libtorrent" "double_conversion" "qtbase" "qttools" "qbittorrent")

	# 创建这个空数组。在此数组中列出或添加到此数组的模块将从默认模块列表中删除，从而更改所有或安装的行为
	delete=()

	# 创建这个空数组。在此数组中列出或添加到此数组的包将从默认包列表中删除，从而更改已安装依赖项的列表
	delete_pkgs=()

	# 动态打印脚本的一些环境值的函数。在帮助部分和脚本输出中使用。
	_print_env() {
		printf '\n%b\n' " ${uyc} 现在使用的环境变量${cend}"
		printf '%b\n' " ${clr}  qbt_cross_name=${cend}${clm}${qbt_cross_name}${cend}"
		printf '%b\n' " ${clr}  qbt_build_tool=${cend}${clm}${qbt_build_tool}${cend}"
		printf '%b\n' " ${clr}  qbt_qbittorrent_tag=${cend}${clm}${github_tag[qbittorrent]}${cend}"
		printf '%b\n' " ${clr}  qbt_libtorrent_version=${cend}${clm}${qbt_libtorrent_version}${cend}"
		printf '%b\n' " ${clr}  qbt_libtorrent_tag=${cend}${clm}${github_tag[libtorrent]}${cend}"
		printf '%b\n' " ${clr}  qbt_qt_version=${cend}${clm}${qbt_qt_version}${cend}"
		printf '%b\n' " ${clr}  qbt_qt_tag=${cend}${clm}${github_tag[qtbase]}${cend}"
		printf '%b\n' " ${clr}  qbt_boost_tag=${cend}${clm}${github_tag[boost]}${cend}"
		printf '%b\n' " ${clr}  qBittorrent_version=${cend}${clm}${qBittorrent_version}${cend}"
		printf '%b\n' " ${clr}  qbt_revision_url=${cend}${clm}${qbt_revision_url}${cend}"
		printf '%b\n' " ${clr}  qbt_patches_url=${cend}${clm}${qbt_patches_url}${cend}"
		printf '%b\n' " ${clr}  qbt_skip_icu=${cend}${clm}${qbt_skip_icu}${cend}"
		printf '%b\n' " ${clr}  qbt_libtorrent_master_jamfile=${cend}${clm}${qbt_libtorrent_master_jamfile}${cend}"
		printf '%b\n' " ${clr}  qbt_workflow_files=${cend}${clm}${qbt_workflow_files}${cend}"
		printf '%b\n' " ${clr}  qbt_workflow_artifacts=${cend}${clm}${qbt_workflow_artifacts}${cend}"
		printf '%b\n' " ${clr}  qbt_cache_dir=${cend}${clm}${qbt_cache_dir}${cend}"
		printf '%b\n' " ${clr}  qbt_optimise_strip=${cend}${clm}${qbt_optimise_strip}${cend}"
		printf '%b\n' " ${clr}  qbt_build_debug=${cend}${clm}${qbt_build_debug}${cend}"
	}

	# 根据 qmake、cmake、strip 和 debug 的使用动态测试更改设置
	if [[ "${qbt_build_debug}" = "yes" ]]; then
		qbt_optimise_strip="no"
		qbt_cmake_debug='ON'
		qbt_libtorrent_debug='debug-symbols=on'
		qbt_qbittorrent_debug='--enable-debug'
	else
		qbt_cmake_debug='OFF'
	fi

	# 根据 qmake、cmake、strip 和 debug 的使用动态测试更改设置
	if [[ "${qbt_optimise_strip}" = "yes" && "${qbt_build_debug}" = "no" ]]; then
		qbt_strip_qmake='strip'
		qbt_strip_flags='-s'
	else
		qbt_strip_qmake='-nostrip'
		qbt_strip_flags=''
	fi

	# 根据 qmake、cmake、strip 和 debug 的使用动态测试更改设置
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

	# 如果我们正在交叉编译然后引导我们为目标架构设置的交叉编译工具否则设置本机架构并删除 debian 交叉编译工具
	if [[ "${multi_arch_options[${qbt_cross_name}]}" == "${qbt_cross_name}" ]]; then
		_multi_arch info_bootstrap
	else
		cross_arch="$(uname -m)"
		delete_pkgs+=("crossbuild-essential-${cross_arch}")
	fi

	# 如果是 Alpine 则删除我们不使用的模块并设置所需的包数组
	if [[ "${what_id}" =~ ^(alpine)$ ]]; then
		delete+=("glibc")
		[[ -z "${qbt_cache_dir}" ]] && delete_pkgs+=("coreutils" "gpg")
		qbt_required_pkgs=("autoconf" "automake" "bash" "bash-completion" "build-base" "coreutils" "curl" "git" "gpg" "pkgconf" "libtool" "perl" "python${qbt_python_version}" "python${qbt_python_version}-dev" "py${qbt_python_version}-numpy" "py${qbt_python_version}-numpy-dev" "linux-headers" "ttf-freefont" "graphviz" "cmake" "re2c")
	fi

	# 如果基于 debian，则设置所需的包数组
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
		[[ -z "${qbt_cache_dir}" ]] && delete_pkgs+=("autopoint" "gperf")
		qbt_required_pkgs=("autopoint" "gperf" "gettext" "texinfo" "gawk" "bison" "build-essential" "crossbuild-essential-${cross_arch}" "curl" "pkg-config" "automake" "libtool" "git" "openssl" "perl" "python${qbt_python_version}" "python${qbt_python_version}-dev" "python${qbt_python_version}-numpy" "unzip" "graphviz" "re2c")
	fi

	# 默认情况下删除此模块，除非作为脚本的第一个参数提供。
	if [[ "${1}" != 'install' ]]; then
		delete+=("install")
	fi

	# 如果 icu 模块作为位置参数提供，请不要删除它。
	# 否则默认跳过 icu，除非提供 -i 标志。
	if [[ "${qbt_skip_icu}" != 'yes' && "${*}" =~ ([[:space:]]|^)"icu"([[:space:]]|$) ]]; then
		qbt_skip_icu="no"
	elif [[ "${qbt_skip_icu}" != "no" ]]; then
		delete+=("icu")
	fi

	# 如果未指定 cmake，则配置默认依赖项和模块
	if [[ "${qbt_build_tool}" != 'cmake' ]]; then
		delete+=("double_conversion")
		delete_pkgs+=("unzip" "ttf-freefont" "graphviz" "cmake" "re2c")
	else
		[[ "${qbt_skip_icu}" != "no" ]] && delete+=("icu")
	fi

	# 将工作目录设置为我们当前的位置，所有的东西都与这个位置有关。
	qbt_working_dir="$(pwd)"

	# 与 printf 一起使用。使用 qbt_working_dir 变量，但 ${HOME} 路径被替换为文字 ~
	qbt_working_dir_short="${qbt_working_dir/${HOME}/\~}"

	# 安装相对于脚本位置。
	qbt_install_dir="${qbt_working_dir}/qbt-build"

	release_info_dir="${qbt_install_dir}/release_info"

	# 与 printf 一起使用。使用 qbt_install_dir 变量，但 ${HOME} 路径被替换为文字 ~
	qbt_install_dir_short="${qbt_install_dir/${HOME}/\~}"

	# 在隔离脚本之前获取本地用户 $PATH，方法是在 _set_build_directory 函数中将 HOME 设置为安装目录。
	qbt_local_paths="$PATH"
}

# 此函数将从 qbt_required_pkgs 数组中检查定义的依赖项列表。像python3-dev这样的应用是动态设置的
_check_dependencies() {
	printf '\n%b\n' " ${ulbc} ${tb}检查所需的核心依赖${cend}"

	# 从 qbt_required_pkgs 数组中删除 delete_pkgs 中的包
	for target in "${delete_pkgs[@]}"; do
		for i in "${!qbt_required_pkgs[@]}"; do
			if [[ "${qbt_required_pkgs[i]}" == "${target}" ]]; then
				unset 'qbt_required_pkgs[i]'
			fi
		done
	done

	# 重建数组以从 0 开始排序索引
	qbt_required_pkgs=("${qbt_required_pkgs[@]}")

	# 这将检查操作系统指定依赖项的 qbt_required_pkgs 数组以查看它们是否已安装
	for pkg in "${qbt_required_pkgs[@]}"; do

		if [[ "${what_id}" =~ ^(alpine)$ ]]; then
			pkgman() { apk info -e "${pkg}"; }
		fi

		if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
			pkgman() { dpkg -s "${pkg}"; }
		fi

		if pkgman > /dev/null 2>&1; then
			printf '%b\n' " ${ugc} ${pkg}"
		else
			if [[ -n "${pkg}" ]]; then
				deps_installed="no"
				printf '%b\n' " ${urc} ${pkg}"
				qbt_checked_required_pkgs+=("$pkg")
			fi
		fi
	done

	# 检查用户是否能够安装依赖项，如果是则执行，如果否则退出。
	if [[ "${deps_installed}" == "no" ]]; then
		if [[ "$(id -un)" == 'root' ]]; then
			printf '\n%b\n' " ${ulbc} ${cg}更新中${cend}"

			if [[ "${what_id}" =~ ^(alpine)$ ]]; then
				apk update --repository="${CDN_URL}"
				apk upgrade --repository="${CDN_URL}"
				apk fix
			fi

			if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
				apt-get update -y
				apt-get upgrade -y
				apt-get autoremove -y
			fi

			[[ -f /var/run/reboot-required ]] && {
				printf '\n%b\n\n' " ${cr}这台机器需要重新启动才能继续安装。请立即重启。${cend}"
				exit
			}

			printf '\n%b\n' " ${ulbc}${cg} 安装所需的依赖项${cend}"

			if [[ "${what_id}" =~ ^(alpine)$ ]]; then
				if ! apk add "${qbt_checked_required_pkgs[@]}" --repository="${CDN_URL}"; then
					printf '\n'
					exit 1
				fi
			fi

			if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
				if ! apt-get install -y "${qbt_checked_required_pkgs[@]}"; then
					printf '\n'
					exit 1
				fi
			fi

			# printf '%b\n' " ${ugc}${cg} 依赖安装！${cend}"
			deps_installed="yes"
		else
			printf '\n%b\n' " ${tb}在使用此脚本之前，请请求或安装缺少的核心依赖项${cend}"

			if [[ "${what_id}" =~ ^(alpine)$ ]]; then
				printf '\n%b\n\n' " ${clr}apk add${cend} ${qbt_checked_required_pkgs[*]}"
			fi

			if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
				printf '\n%b\n\n' " ${clr}apt-get install -y${cend} ${qbt_checked_required_pkgs[*]}"
			fi

			exit
		fi
	fi

	# 所有的依赖检查都通过了 print
	if [[ "${deps_installed}" != "no" ]]; then
		printf '%b\n' " ${ugc}${cg} 所有依赖已安装 ${cend}"
		echo "" > "${qbt_working_dir}/deps_installed"
	fi
}

# 这是一个命令测试函数：_cmd exit 1
_cmd() {
	if ! "${@}"; then
		printf '\n%b\n\n' "命令：${clr}${*}${cend} 失败"
		exit 1
	fi
}

# 这是一个命令测试函数，用于测试编译命令是否失败
_post_command() {
	outcome=("${PIPESTATUS[@]}")
	[[ -n "${1}" ]] && command_type="${1}"
	if [[ "${outcome[*]}" =~ [1-9] ]]; then
		printf '\n%b\n\n' " ${urc}${clr} 错误：${command_type:-tested} 命令产生了大于 0 的退出代码 - 检查日志${cend}"
		exit 1
	fi
}

# 此函数用于在尝试 cd 之前测试目录是否存在，如果不存在则失败并退出代码。
_pushd() {
	if ! pushd "$@" &> /dev/null; then
		printf '\n%b\n' "该目录不存在。"
		printf '\n%b\n\n' "${clr}${1}${cend}"
		exit 1
	fi
}

_popd() {
	if ! popd &> /dev/null; then
		printf '%b\n' "该目录不存在。"
		exit 1
	fi
}

# 此函数确保 tee 所需的日志目录和路径存在
_tee() {
	[[ "$#" -eq 1 && "${1%/*}" =~ / ]] && mkdir -p "${1%/*}"
	[[ "$#" -eq 2 && "${2%/*}" =~ / ]] && mkdir -p "${2%/*}"
	command tee "$@"
}

# 错误函数
_error_tag() {
	[[ "${github_tag[*]}" =~ error_tag ]] && {
		printf '\n'
		exit
	}
}

# _curl 测试下载功能 - 默认为无代理 - _curl 为测试功能，_curl_curl 为命令功能
_curl_curl() {
	"$(type -P curl)" -sNL4fq --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 "${qbt_curl_proxy[@]}" "${@}"
}

_curl() {
	if ! _curl_curl "${@}"; then
		return 1
	fi
}

# git 测试下载功能 - 默认是没有代理- git 是测试函数，_git_git 是命令函数
_git_git() {
	"$(type -P git)" "${qbt_git_proxy[@]}" "${@}"
}

_git() {
	if [[ "${2}" == '-t' ]]; then
		git_test_cmd=("${1}" "${2}" "${3}")
	else
		[[ "${9}" =~ https:// ]] && git_test_cmd=("${9}")   # 在我们的 qttools 下载文件夹功能中排名第 9
		[[ "${11}" =~ https:// ]] && git_test_cmd=("${11}") # 在我们的下载文件夹功能中排名第 11 位
	fi

	if ! _curl -fIL "${git_test_cmd[@]}" &> /dev/null; then
		printf '\n%b\n\n' " ${cy}Git 测试 1：您的代理设置或网络连接有问题${cend}"
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
			printf '\n%b\n\n' " ${cy}Git 测试 2：您的代理设置或网络连接有问题${cend}"
			exit
		fi
	fi
}

_test_git_ouput() {
	if [[ "${1}" == 'error_tag' ]]; then
		printf '\n%b\n' "${cy} 抱歉，提供的 ${2} 标签 ${cr}${3}${cend}${cy} 无效${cend}"
	fi
}

#调试函数
_debug() {
	if [[ "${script_debug_urls}" == "yes" ]]; then
		mapfile -t github_url_sorted < <(printf '%s\n' "${!github_url[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}github_url${cend}"
		for n in "${github_url_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${github_url[$n]}${cend}" #: ${github_url[$n]}"
		done

		mapfile -t github_tag_sorted < <(printf '%s\n' "${!github_tag[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}github_tag${cend}"
		for n in "${github_tag_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${github_tag[$n]}${cend}" #: ${github_url[$n]}"
		done

		mapfile -t app_version_sorted < <(printf '%s\n' "${!app_version[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}app_version${cend}"
		for n in "${app_version_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${app_version[$n]}${cend}" #: ${github_url[$n]}"
		done

		mapfile -t source_archive_url_sorted < <(printf '%s\n' "${!source_archive_url[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}source_archive_url${cend}"
		for n in "${source_archive_url_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${source_archive_url[$n]}${cend}" #: ${github_url[$n]}"
		done

		mapfile -t qbt_workflow_archive_url_sorted < <(printf '%s\n' "${!qbt_workflow_archive_url[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}qbt_workflow_archive_url${cend}"
		for n in "${qbt_workflow_archive_url_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${qbt_workflow_archive_url[$n]}${cend}" #: ${github_url[$n]}"
		done

		mapfile -t source_default_sorted < <(printf '%s\n' "${!source_default[@]}" | sort)
		printf '\n%b\n\n' " ${umc} ${cly}source_default${cend}"
		for n in "${source_default_sorted[@]}"; do
			printf '%b\n' " ${clg}$n${cend}: ${clb}${source_default[$n]}${cend}" #: ${github_url[$n]}"
		done

		printf '\n%b\n' " ${umc} ${cly}Tests${cend}"
		printf '\n%b\n' " ${clg}boost_url_status:${cend} ${clb}${boost_url_status}${cend}"
		printf '%b\n' " ${clg}test_url_status:${cend} ${clb}${test_url_status}${cend}"

		printf '\n'
		exit
	fi
}

# 此函数全局设置一些编译器标志 - b2 设置在 ~/user-config.jam 中设置，在 _installation_modules 函数中设置
_custom_flags_set() {
	CXXFLAGS="${qbt_optimize/*/${qbt_optimize} }-std=${cxx_standard} -static -w -Wno-psabi -I${include_dir}"
	CPPFLAGS="${qbt_optimize/*/${qbt_optimize} }-static -w -Wno-psabi -I${include_dir}"
	LDFLAGS="${qbt_optimize/*/${qbt_optimize} }-static ${qbt_strip_flags} -L${lib_dir} -pthread"
}

_custom_flags_reset() {
	CXXFLAGS="${qbt_optimize/*/${qbt_optimize} } -w -std=${cxx_standard}"
	CPPFLAGS="${qbt_optimize/*/${qbt_optimize} } -w"
	LDFLAGS=""
}

# 此函数将 qbittorrent-nox 的完整静态编译安装到 /usr/local/bin for root 或 ${HOME}/bin for non root
_install_qbittorrent() {
	if [[ -f "${qbt_install_dir}/completed/qbittorrent-nox" ]]; then
		if [[ "$(id -un)" == 'root' ]]; then
			mkdir -p "/usr/local/bin"
			cp -vrf "${qbt_install_dir}/completed/qbittorrent-nox" "/usr/local/bin"
		else
			mkdir -p "${HOME}/bin"
			cp -vrf "${qbt_install_dir}/completed/qbittorrent-nox" "${LOCAL_USER_HOME}/bin"
		fi

		printf '\n%b\n' " ${ulbc} qbittorrent-nox 已安装！${cend}"
		printf '\n%b\n' " 使用此命令运行它："
		[[ "$(id -un)" == 'root' ]] && printf '\n%b\n\n' " ${cg}qbittorrent-nox${cend}" || printf '\n%b\n\n' " ${cg}~/bin/qbittorrent-nox${cend}"
		exit
	else
		printf '\n%b\n\n' " ${urc} qbittorrent-nox 尚未编译到定义的安装目录："
		printf '\n%b\n' "${cg}${qbt_install_dir_short}/completed${cend}"
		printf '\n%b\n\n' "请先使用脚本编译它然后安装"
		exit
	fi
}

# 脚本版本检查
_script_version() {
	script_version_remote="$(_curl -sL "${script_url}" | sed -rn 's|^script_version="(.*)"$|\1|p')"

	semantic_version() {
		local test_array
		read -ra test_array < <(printf "%s" "${@//./ }")
		printf "%d%03d%03d%03d" "${test_array[@]}"
	}

	if [[ "$(semantic_version "${script_version}")" -lt "$(semantic_version "${script_version_remote}")" ]]; then
		printf '\n%b\n' " ${tbk}${urc}${cend} 脚本更新可用！版本 - ${cly}local:${clr}${script_version}${cend} ${cly}remote:${clg}${script_version_remote}${cend}"
		printf '\n%b' " ${ugc} curl -sLo ~/qbittorrent-nox-static.sh https://git.io/qbstatic${cend}"
	else
		printf '\n%b' " ${ugc} 当前使用的脚本版本: ${clg}${script_version}${cend}"
	fi
}

# 正常使用和代理使用的 URL 测试 - 在处理 URL 函数之前确保我们可以到达 google.com
_test_url() {
	test_url_status="$(_curl -o /dev/null --head --write-out '%{http_code}' "https://github.com")"
	if [[ "${test_url_status}" -eq "200" ]]; then
		printf '\n%b\n' " ${ugc} 测试 Github 网址 => ${cg}通过${cend}"
	else
		printf '\n%b\n' " ${urc} ${cy}测试 URL 失败：${cend} ${cly}您的代理设置或网络连接可能有问题${cend}"
		exit
	fi
}

# 此函数设置编译和安装目录。如果参数 -b 用于设置编译目录，则该目录将被设置和使用。
# 如果未指定或未使用开关，则默认为相对于脚本位置的硬编码路径 - qbittorrent-build
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

	# 根据安装路径设置lib和include目录路径。
	include_dir="${qbt_install_dir}/include"
	lib_dir="${qbt_install_dir}/lib"

	# 定义一些编译特定的变量
	LOCAL_USER_HOME="${HOME}" # 在我们将 HOME 包含到编译目录之前获取本地用户的主目录路径。
	HOME="${qbt_install_dir}"
	PATH="${qbt_install_dir}/bin${PATH:+:${qbt_local_paths}}"
	PKG_CONFIG_PATH="${lib_dir}/pkgconfig"
}

# 这个函数是我们设置你的 URL 和我们与其他函数一起使用的 github 标签信息的地方。
# shellcheck disable=SC1072
_set_module_urls() {
	# 更新 _script_version 函数的检查 url
	script_url="https://raw.githubusercontent.com/userdocs/qbittorrent-nox-static/master/qbittorrent-nox-static.sh"

	# 为这个脚本使用的所有应用程序创建 github_url 关联数组，我们称它们为 ${github_url[app_name]}
	declare -gA github_url
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
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

	# 为这个脚本使用的所有应用程序创建 github_tag 关联数组，我们称它们为 ${github_tag[app_name]}
	declare -gA github_tag
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
		github_tag[cmake_ninja]="$(_git_git ls-remote -q -t --refs "${github_url[cmake_ninja]}" | awk '{sub("refs/tags/", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
		if [[ "${what_version_codename}" =~ ^(jammy)$ ]]; then
			github_tag[glibc]="glibc-2.37"
		else # "$(_git_git ls-remote -q -t --refs https://sourceware.org/git/glibc.git | awk '/\/tags\/glibc-[0-9]\.[0-9]{2}$/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
			github_tag[glibc]="glibc-2.31"
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
	github_tag[boost]=$(_git_git ls-remote -q -t --refs "${github_url[boost]}" | awk '{sub("refs/tags/", "");sub("(.*)(rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)
	github_tag[libtorrent]="$(_git_git ls-remote -q -t --refs "${github_url[libtorrent]}" | awk '/'"v${qbt_libtorrent_version}"'/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qtbase]="$(_git_git ls-remote -q -t --refs "${github_url[qtbase]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qttools]="$(_git_git ls-remote -q -t --refs "${github_url[qttools]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qbittorrent]="$(_git_git ls-remote -q -t --refs "${github_url[qbittorrent]}" | awk '{sub("refs/tags/", "");sub("(.*)(-[^0-9].*|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"

	# 为这个脚本使用的所有应用程序创建 app_version 关联数组，我们称它们为 ${app_version[app_name]}
	declare -gA app_version
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
		app_version[cmake_debian]="${github_tag[cmake_ninja]%_*}"
		app_version[ninja_debian]="${github_tag[cmake_ninja]#*_}"
		app_version[glibc]="${github_tag[glibc]#glibc-}"
	else
		app_version[cmake]="$(apk info -d cmake | awk '/cmake-/{sub("(cmake-)", "");sub("(-r)", ""); print $1 }')"
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

	# 为这个脚本使用的所有应用程序创建 source_archive_url 关联数组，我们称它们为 ${source_archive_url[app_name]}
	declare -gA source_archive_url
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
		source_archive_url[cmake_ninja]="https://github.com/userdocs/qbt-cmake-ninja-crossbuilds/releases/latest/download/${what_id}-${what_version_codename}-cmake-$(dpkg --print-architecture).tar.xz"
		source_archive_url[glibc]="https://ftpmirror.gnu.org/gnu/libc/${github_tag[glibc]}.tar.xz"
	fi
	source_archive_url[zlib]="https://github.com/zlib-ng/zlib-ng/archive/refs/heads/develop.tar.gz"
	source_archive_url[iconv]="https://mirrors.dotsrc.org/gnu/libiconv/$(grep -Eo 'libiconv-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(_curl https://mirrors.dotsrc.org/gnu/libiconv/) | sort -V | tail -1)"
	source_archive_url[icu]="https://github.com/unicode-org/icu/releases/download/${github_tag[icu]}/icu4c-${app_version[icu]/-/_}-src.tgz"
	source_archive_url[double_conversion]="https://github.com/google/double-conversion/archive/refs/tags/${github_tag[double_conversion]}.tar.gz"
	source_archive_url[openssl]="https://github.com/openssl/openssl/releases/download/${github_tag[openssl]}/${github_tag[openssl]}.tar.gz"
	source_archive_url[boost]="https://boostorg.jfrog.io/artifactory/main/release/${github_tag[boost]/boost-/}/source/${github_tag[boost]//[-\.]/_}.tar.gz"
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

	# 为该脚本使用的所有应用程序创建 qbt_workflow_archive_url 关联数组，我们称它们为 ${qbt_workflow_archive_url[app_name]}
	declare -gA qbt_workflow_archive_url
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
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

	# 工作流覆盖选项
	declare -gA qbt_workflow_override
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
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

	# 我们用于下载功能的默认源类型
	declare -gA source_default
	if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
		source_default[cmake_ninja]="file"
		source_default[glibc]="file"
	fi
	source_default[zlib]="folder"
	source_default[iconv]="file"
	source_default[icu]="file"
	source_default[double_conversion]="file"
	source_default[openssl]="file"
	source_default[boost]="file"
	source_default[libtorrent]="file"
	source_default[qtbase]="file"
	source_default[qttools]="file"
	source_default[qbittorrent]="folder"

	# 定义一些我们用来检查或测试某些URL状态的测试URL
	boost_url_status="$(_curl -so /dev/null --head --write-out '%{http_code}' "https://boostorg.jfrog.io/artifactory/main/release/${app_version[boost]}/source/boost_${app_version[boost]//./_}.tar.gz")"
	return
}

# 此函数验证默认值函数中数组 qbt_modules 中的模块名称。
_installation_modules() {
	# 删除模块 - 使用 delete 数组从 qbt_modules 数组中取消设置
	for target in "${delete[@]}"; do
		for deactivated in "${!qbt_modules[@]}"; do
			[[ "${qbt_modules[${deactivated}]}" == "${target}" ]] && unset 'qbt_modules[${deactivated}]'
		done
	done
	unset target deactivated

	# 对于通过的任何模块参数，测试它们是否存在于 qbt_modules 数组中或将 qbt_modules_test 设置为失败
	for passed_params in "${@}"; do
		if [[ ! "${qbt_modules[*]}" =~ ${passed_params} ]]; then
			qbt_modules_test="fail"
		fi
	done
	unset passed_params

	if [[ "${qbt_modules_test}" != 'fail' && "${#}" -ne '0' ]]; then
		if [[ "${1}" == "all" ]]; then
			# 如果全部作为模块传递并且一旦参数 check = pass 触发了这个条件，从 qbt_modules 数组中删除 to 只留下要激活的模块
			unset 'qbt_modules[0]'
			# 重建 qbt_modules 数组，以便在我们之前修改和删除项目后从 0 开始索引。
			qbt_modules=("${qbt_modules[@]}")
		else # 只激活作为参数传递的模块，其余默认跳过
			unset 'qbt_modules[0]'
			read -ra qbt_modules_skipped <<< "${qbt_modules[@]}"
			declare -gA skip_modules
			for selected in "${@}"; do
				for full_list in "${!qbt_modules_skipped[@]}"; do
					[[ "${selected}" == "${qbt_modules_skipped[full_list]}" ]] && qbt_modules_skipped[full_list]="${clm}${selected}${cend}"
				done
			done
			unset selected
			qbt_modules=("${@}")
		fi

		for modules_skip in "${qbt_modules[@]}"; do
			skip_modules["${modules_skip}"]="no"
		done
		unset modules_skip

		# 创建我们需要的目录。
		mkdir -p "${qbt_install_dir}/logs"
		mkdir -p "${PKG_CONFIG_PATH}"
		mkdir -p "${qbt_install_dir}/completed"

		# 设置一些我们需要的python变量。
		python_major="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[0])")"
		python_minor="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[1])")"

		python_short_version="${python_major}.${python_minor}"

		printf '%b\n' "using gcc : : : <cflags>${qbt_optimize/*/${qbt_optimize} }-std=${cxx_standard} <cxxflags>${qbt_optimize/*/${qbt_optimize} }-std=${cxx_standard} ;${tn}using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" > "${HOME}/user-config.jam"

		# printf 编译目录。
		printf '\n%b' " ${uyc}${tb} 编译目录${cend} : ${clc}${qbt_install_dir_short}${cend}"

		# 一些基本的帮助
		# printf '\n%b' " ${uyc}${tb} 脚本帮助${cend} : ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-h${cend}"
	fi
}

# 此函数将通过变量 patches_github_url 测试使用的标签是否存在 Jamfile 补丁文件。
_apply_patches() {
	[[ -n "${1}" ]] && app_name="${1}"
	# 通过将 app_version[libtorrent] 变量转换为下划线，开始定义我们将使用的默认主分支。结果是动态的，可以是：RC_1_0、RC_1_1、RC_1_2、RC_2_0 等等。
	default_jamfile="${app_version[libtorrent]//./\_}"

	# 删除第二个下划线后的所有内容。有时标签会很短，比如 v2.0，所以如果只有一个，我们需要确保不要删除下划线。
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
		printf '\n%b\n' " ${uyc} 使用默认值，已创建以下这些目录:${cend}"

		for patch_info in "${qbt_modules[@]}"; do
			[[ -n "${app_version["${patch_info}"]}" ]] && printf '%b\n' " ${clc} ${qbt_install_dir_short}/patches/${patch_info}/${app_version["${patch_info}"]}${cend}"
		done
		unset patch_info
		printf '%b\n' " ${ucc} 如果在上面的这些目录中找到名为 ${clc}patch${cend} 的补丁文件，它将被应用到具有匹配标签的相关模块."
	else
		patch_dir="${qbt_install_dir}/patches/${app_name}/${app_version[${app_name}]}"
		patch_file="${patch_dir}/patch"
		patch_file_url="https://raw.githubusercontent.com/${qbt_patches_url}/master/patches/${app_name}/${app_version[${app_name}]}/patch"

		if [[ "${app_name}" == "qbittorrent" ]]; then
			patch_file="${patch_dir}/${qBittorrent_version}.patch"
			patch_file_url="https://raw.githubusercontent.com/${qbt_patches_url}/master/patches/${app_name}/${app_version[${app_name}]}/${qBittorrent_version}.patch"
		fi

		if [[ "${app_name}" == "libtorrent" ]]; then
			patch_jamfile="${patch_dir}/Jamfile"
			patch_jamfile_url="https://raw.githubusercontent.com/${qbt_patches_url}/master/patches/${app_name}/${app_version[${app_name}]}/Jamfile"
		fi

		# 如果补丁文件存在于与编译配置匹配的模块版本文件夹中，则使用它。
		if [[ -f "${patch_file}" ]]; then
			printf '%b\n\n' " ${ugc}${clr} 应用当前的 ${cend} ${clc}${patch_file}${cend} ${clm}${app_name}${cend} ${cly}${app_version[${app_name}]}${cend} ${cr} 补丁 ${cend}"
		else
			# 否则检查补丁仓库中是否有可用的远程主机补丁文件
			if _curl --create-dirs "${patch_file_url}" -o "${patch_file}"; then
				printf '%b\n\n' "${ugc} 已下载 ${cly}${patch_file_url}${cend} 的 ${clm}${app_name}${cend} patch文件到 ${cly} ${patch_file} ${cend}${cr} ${cend}"
			fi
		fi

		# Libtorrent 特定的东西
		if [[ "${app_name}" == "libtorrent" ]]; then
			# cosmetics
			[[ "${source_default[libtorrent]}" == "folder" && ! -d "${qbt_cache_dir}/${app_name}" ]] && printf '\n'

			if [[ "${qbt_libtorrent_master_jamfile}" == "yes" ]]; then
				_curl --create-dirs "https://raw.githubusercontent.com/arvidn/libtorrent/${default_jamfile}/Jamfile" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '%b\n\n' " ${ugc}${cr} 使用 libtorrent 分支主 Jamfile 文件${cend}"
			elif [[ -f "${patch_dir}/Jamfile" ]]; then
				cp -vf "${patch_dir}/Jamfile" "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '%b\n\n' " ${ugc}${cr} 使用现有的自定义 Jamfile 文件${cend}"
			else
				if _curl --create-dirs "${patch_jamfile_url}" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"; then
					printf '%b\n\n' " ${ugc}${cr} 使用下载的自定义 Jamfile 文件${cend}"
				else
					printf '%b\n\n' " ${ugc}${cr} 使用 libtorrent ${github_tag[libtorrent]} Jamfile 文件${cend}"
				fi
			fi
		fi

		# 应用补丁文件
		if [[ -f "${patch_file}" ]]; then
			if patch -p1 < "${patch_file}"; then
				printf '\n%b\n\n' " ${ugc}${clr} 已应用 >> ${cend}${clc}${patch_file}${cend} ${cr} 的补丁文件${cend}"
				[[ -d ".git" ]] && git diff > "${release_info_dir}/${app_name}-git.patch"
			fi
		fi

		# 从源目录复制修改后的文件
		if [[ -d "${patch_dir}/source" && "$(ls -A "${patch_dir}/source")" ]]; then
			printf '%b\n\n' " ${urc} ${cly}从补丁源目录复制文件${cend}"
			cp -vrf "${patch_dir}/source/". "${qbt_dl_folder_path}/"
		fi

	fi
}

# 一个统一的下载函数来处理脚本可以采用的各种选项和方向。
_download() {
	_pushd "${qbt_install_dir}"

	[[ -n "${1}" ]] && app_name="${1}"

	# 我们将源档案和文件夹下载到的位置
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

_cache_dirs() {
	# 如果路径不是以 / 开头，则通过在 qbt_working_dir 路径前加上使其成为完整路径
	if [[ ! "${qbt_cache_dir}" =~ ^/ ]]; then
		qbt_cache_dir="${qbt_working_dir}/${qbt_cache_dir}"
	fi

	qbt_dl_dir="${qbt_cache_dir}"
	qbt_dl_file_path="${qbt_dl_dir}/${app_name}.tar.xz"
	qbt_dl_folder_path="${qbt_dl_dir}/${app_name}"

	if [[ "${qbt_workflow_files}" == "yes" || "${app_name}" == "cmake_ninja" ]]; then
		source_default["${app_name}"]="file"
	elif [[ "${qbt_cache_dir_options}" == "bs" || -d "${qbt_dl_folder_path}" ]]; then
		source_default["${app_name}"]="folder"
	fi

	return
}

# 此函数用于根据标签下载 git 版本。
_download_folder() {
	# 设置此项以避免在克隆某些模块时出现警告
	_git_git config --global advice.detachedHead false

	# 如果不使用工件，请在我们再次下载或复制它们之前删除编译目录中的源文件（如果存在）
	[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
	[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"

	# 如果在提供的路径中不存在 app_name 缓存目录，并且我们正在引导，则使用此 echo
	if [[ "${qbt_cache_dir_options}" == "bs" && ! -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${ulbc} 将带有标签 ${cly}${github_tag[${app_name}]}${cend} 的 ${clm}${app_name}${cend} 缓存到 ${clc}${clc}${qbt_dl_folder_path}${cend} ${cend} 来自 ${cly}${cly}${github_url[${app_name}]}${cend}"
	fi

	# 如果缓存目录打开并且 app_name 文件夹不存在则通过克隆默认源获取文件夹
	if [[ "${qbt_cache_dir_options}" != "bs" && ! -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${ulbc} 准备拉取 ${cly}${cly}${github_url[${app_name}]}${cend} ${cly}${github_tag[${app_name}]}${cend} 的 ${clm}${app_name}${cend} 源码到 ${clc}${clc}${qbt_dl_folder_path}/${cend}${cend}"
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

	# 如果在提供的路径中存在一个 app_name 缓存目录，并且我们正在引导，那么使用这个
	if [[ "${qbt_cache_dir_options}" == "bs" && -d "${qbt_dl_folder_path}" ]]; then
		printf '\n%b\n\n' " ${ugc} ${clb}${app_name}${cend} - 更新目录 ${clc}${qbt_dl_folder_path}${cend}"
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
		printf '\n%b\n\n' " ${ulbc} 从缓存 ${clc}${qbt_cache_dir}/${app_name}${cend} 中复制 ${clm}${app_name}${cend} 和标签 ${cly}${github_tag[${app_name}]}${cend} 到 ${clc}${qbt_install_dir}/${app_name}${cend}"
		cp -vrf "${qbt_dl_folder_path}" "${qbt_install_dir}/"
	fi

	if [[ "${qbt_cache_dir_options}" != "bs" ]]; then
		mkdir -p "${qbt_install_dir}/${app_name}${sub_dir}"
		_pushd "${qbt_install_dir}/${app_name}${sub_dir}"
	fi

	printf '%s' "${github_url[${app_name}]}" |& _tee "${qbt_install_dir}/logs/${app_name}_github_url.log" > /dev/null

	return
}

# 此函数用于下载源代码存档
_download_file() {
	if [[ -f "${qbt_dl_file_path}" && "${qbt_workflow_artifacts}" == "no" ]]; then
		# 这会检查存档是否损坏或为空检查顶级文件夹并在没有结果时退出，即存档为空 - 所以我们执行 rm 和空替换
		_cmd grep -Eqom1 "(.*)[^/]" <(tar tf "${qbt_dl_file_path}")
		# 删除任何现有的提取档案和档案
		rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"
	fi

	if [[ "${qbt_cache_dir_options}" != "bs" && ! -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n' " ${ulbc} 准备下载 ${cly}${qbt_dl_source_url}${cend} 的 ${clm}${app_name}${cend} 源码到 ${clc}${qbt_dl_file_path}${cend}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" == "bs" && ! -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n' " ${ulbc} 缓存 ${clm}${app_name}${cend} ${cly}${source_type}${cend} 文件到 ${clc}${qbt_cache_dir}/${app_name}.tar.xz${cend} - ${cly}${qbt_dl_source_url}${cend}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" == "bs" && -f "${qbt_dl_file_path}" ]]; then
		[[ "${qbt_cache_dir_options}" == "bs" ]] && printf '\n%b\n' " ${ulbc} 更新 ${clm}${app_name}${cend} 缓存的 ${cly}${source_type}${cend} 文件 - ${clc}${qbt_cache_dir}/${app_name}.tar.xz${cend}"
	elif [[ -n "${qbt_cache_dir}" && "${qbt_cache_dir_options}" != "bs" && -f "${qbt_dl_file_path}" ]]; then
		printf '\n%b\n\n' " ${ulbc} 从中提取 ${clm}${app_name}${cend} 缓存的 ${cly}${source_type}${cend} 文件 - ${clc}${qbt_cache_dir}/${app_name}.tar.xz${cend}"
	fi

	if [[ "${qbt_workflow_artifacts}" == "no" ]]; then
		# 使用 curl 下载远程源文件
		if [[ "${qbt_cache_dir_options}" = "bs" || ! -f "${qbt_dl_file_path}" ]]; then
			_curl --create-dirs "${qbt_dl_source_url}" -o "${qbt_dl_file_path}"
		fi
	fi

	# 将提取的目录名称设置为 var 以便于使用或删除它
	qbt_dl_folder_path="${qbt_install_dir}/$(tar tf "${qbt_dl_file_path}" | head -1 | cut -f1 -d"/")"

	printf '%b\n' "${qbt_dl_source_url}" |& _tee "${qbt_install_dir}/logs/${app_name}_${source_type}_archive_url.log" > /dev/null

	[[ "${app_name}" == "cmake_ninja" ]] && additional_cmds=("--strip-components=1")

	if [[ "${qbt_cache_dir_options}" != "bs" ]]; then
		_cmd tar xf "${qbt_dl_file_path}" -C "${qbt_install_dir}" "${additional_cmds[@]}"
		# 如果我们通过源档案下载它，我们不需要 cd 到 boost
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

# 静态库链接修复：检查 $lib_dir 中库的 *.so 和 *.a 版本并更改 *.so 链接以指向静态库，例如libdl.a
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

# 此函数用于删除我们不再需要的文件和文件夹
_delete_function() {
	[[ "${app_name}" != "cmake_ninja" ]] && printf '\n'
	if [[ "${qbt_skip_delete}" != "yes" ]]; then
		printf '%b\n' " ${ugc}${clr} 删除 ${app_name} 缓存的安装文件${cend}"
		[[ -f "${qbt_dl_file_path}" && "${qbt_workflow_artifacts}" == "no" ]] && rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d "${qbt_dl_folder_path}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		_pushd "${qbt_working_dir}"
	else
		printf '%b\n' " ${uyc}${clr} 跳过 ${app_name} 删除${cend}"
	fi
}

#cmake安装
_cmake() {
	if [[ "${qbt_build_tool}" == 'cmake' ]]; then
		printf '\n%b\n' " ${ulbc} ${clb}检查是否需要安装cmake和ninja${cend}"
		mkdir -p "${qbt_install_dir}/bin"

		if [[ "${what_id}" =~ ^(debian|ubuntu)$ ]]; then
			if [[ "$(cmake --version 2> /dev/null | awk 'NR==1{print $3}')" != "${app_version[cmake_debian]}" ]]; then
				_download cmake_ninja
				_post_command "Debian cmake and ninja installation"
				printf '%b\n' " ${uyc} 使用 cmake: ${cly}${app_version[cmake_debian]}"
				printf '%b\n' " ${uyc} 使用 ninja: ${cly}${app_version[ninja_debian]}"
			fi
		fi

		if [[ "${what_id}" =~ ^(alpine)$ ]]; then
			if [[ "$("${qbt_install_dir}/bin/ninja" --version 2> /dev/null | sed 's/\.git//g')" != "${app_version[ninja]}" ]]; then
				_curl "https://github.com/userdocs/qbt-ninja-build/releases/latest/download/ninja-$(apk info --print-arch)" -o "${qbt_install_dir}/bin/ninja"
				_post_command ninja
				chmod 700 "${qbt_install_dir}/bin/ninja"
				printf '%b\n' " ${uyc} 使用 cmake: ${cly}${app_version[cmake]}"
				printf '%b\n' " ${uyc} 使用 ninja: ${cly}${app_version[ninja]}"
			fi
		fi
		printf '%b\n' " ${ugc} ${clg}cmake 和 ninja 已安装并可以使用${cend}"
		cmake_ninja="yes" && echo "" > "${qbt_working_dir}/cmake_ninja"
	fi
	_pushd "${qbt_working_dir}"
}

# 该函数处理脚本的多架构动态。
_multi_arch() {
	if [[ "${multi_arch_options[${qbt_cross_name:-default}]}" == "${qbt_cross_name}" ]]; then
		if [[ "${what_id}" =~ ^(alpine|debian|ubuntu)$ ]]; then
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
						debian | ubuntu)
							printf '\n%b\n\n' " ${urc} 这个 arch - ${cly}${qbt_cross_target}${cend} - 只能在 Alpine OS Host 上交叉编译"
							exit 1
							;;
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
			[[ "${1}" != "bootstrap" ]] && printf '\n%b\n' " ${ugc}${cly} 当前的环境 [ 系统：${what_id} 架构：${qbt_cross_name} 目标：${qbt_cross_target} ]${cend}"

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
					printf '\n%b\n' " ${ulbc} 准备下载 ${clc}https://github.com/hong0980/qbt-musl-cross-make/releases/latest/download/${qbt_cross_host}.tar.xz${cend} 的交叉工具链到 ${clm}${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz${cend} 备用"
					_curl --create-dirs "https://github.com/hong0980/qbt-musl-cross-make/releases/latest/download/${qbt_cross_host}.tar.xz" -o "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz"
				else
					printf '\n%b' " ${ulbc} 提取 ${clm}${qbt_cross_host}.tar.gz${cend} 的交叉工具链到 ${clc}${qbt_cache_dir:-${qbt_install_dir}}/${cend}"
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
				printf '%b\n' "using gcc : ${qbt_cross_boost#gcc-} : ${qbt_cross_host}-g++ : <cflags>${qbt_optimize/*/${qbt_optimize} }-std=${cxx_standard} <cxxflags>${qbt_optimize/*/${qbt_optimize} }-std=${cxx_standard} ;${tn}using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" > "${HOME}/user-config.jam"
				multi_libtorrent=("toolset=${qbt_cross_boost:-gcc}") # ${multi_libtorrent[@]}
				multi_qbittorrent=("--host=${qbt_cross_host}")       # ${multi_qbittorrent[@]}
			fi
			return
		else
			printf '\n%b\n\n' " ${urc} Multiarch 仅适用于 Alpine Linux（本机或 docker）${cend}"
			exit 1
		fi
	else
		multi_openssl=("./config") # ${multi_openssl[@]}
		return
	fi
}

# Github Actions 发布信息
_release_info() {
	_error_tag
	echo -e "\n ${ugc} ${cly}创建 Release 信息${cend}"
	mkdir -p "${release_info_dir}"

	if _git_git ls-remote -t --exit-code "https://github.com/${qbt_revision_url}.git" "${github_tag[qbittorrent]}_${github_tag[libtorrent]}" &> /dev/null; then
		if grep -q '"name": "dependency-version.json"' < <(_curl "https://api.github.com/repos/${qbt_revision_url}/releases/tags/${github_tag[qbittorrent]}_${github_tag[libtorrent]}"); then
			until _curl "https://github.com/${qbt_revision_url}/releases/download/${github_tag[qbittorrent]}_${github_tag[libtorrent]}/dependency-version.json" > "${release_info_dir}/remote-dependency-version.json"; do
				printf '%b\n' "等待 dependency-version.json URL。"
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

		🔵 These source code files are used for workflows: [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files/releases/latest)

		🔵 These builds were created on Alpine linux using [custom prebuilt musl toolchains](https://github.com/userdocs/qbt-musl-cross-make/releases/latest) for:
	RELEASE_INFO

	{
		printf '\n%s\n' "|  Crossarch  | Alpine Cross build files | Arch config |                                                             Tuning                                                              |"
		printf '%s\n' "| :---------: | :----------------------: | :---------: | :-----------------------------------------------------------------------------------------------------------------------------: |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armel ]] && printf '%s\n' "|    armel    |    arm-linux-musleabi    |   armv5te   |                       --with-arch=armv5te --with-tune=arm926ej-s --with-float=soft --with-abi=aapcs-linux                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armhf ]] && printf '%s\n' "|    armhf    |   arm-linux-musleabihf   |   armv6zk   |              --with-arch=armv6zk --with-tune=arm1176jzf-s --with-fpu=vfp --with-float=hard --with-abi=aapcs-linux               |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == armv7 ]] && printf '%s\n' "|    armv7    | armv7l-linux-musleabihf  |   armv7-a   | --with-arch=armv7-a --with-tune=generic-armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-abi=aapcs-linux --with-mode=thumb |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == aarch64 ]] && printf '%s\n' "|   aarch64   |    aarch64-linux-musl    |   armv8-a   |                                               --with-arch=armv8-a --with-abi=lp64                                               |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == x86_64 ]] && printf '%s\n' "|   x86_64    |    x86_64-linux-musl     |    amd64    |                                                               N/A                                                               |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == x86 ]] && printf '%s\n' "|     x86     |     i686-linux-musl      |    i686     |                                        --with-arch=i686 --with-tune=generic --enable-cld                                        |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == s390x ]] && printf '%s\n' "|    s390x    |     s390x-linux-musl     |    zEC12    |                  --with-arch=z196 --with-tune=zEC12 --with-zarch --with-long-double-128 --enable-decimal-float                  |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == powerpc ]] && printf '%s\n' "|   powerpc   |    powerpc-linux-musl    |     ppc     |                                          --enable-secureplt --enable-decimal-float=no                                           |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == ppc64el ]] && printf '%s\n' "| powerpc64le |  powerpc64le-linux-musl  |    ppc64    |                 --with-abi=elfv2 --enable-secureplt --enable-decimal-float=no --enable-targets=powerpcle-linux                  |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips ]] && printf '%s\n' "|    mips     |     mips-linux-musl      |    mips     |                               --with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mipsel ]] && printf '%s\n' "|   mipsel    |    mipsel-linux-musl     |   mips32    |                                -with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips64 ]] && printf '%s\n' "|   mips64    |    mips64-linux-musl     |   mips32    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == mips64el ]] && printf '%s\n' "|  mips64el   |   mips64el-linux-musl    |   mips64    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ "${multi_arch_options[${qbt_cross_name}]}" == riscv64 ]] && printf '%s\n' "|   riscv64   |    riscv64-linux-musl    |   rv64gc    |                                 --with-arch=rv64gc --with-abi=lp64d --enable-autolink-libatomic                                 |"
		printf '\n'
	} >> "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md"

	cat >> "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md" <<- RELEASE_INFO
		## Info about the build matrixes for qbittorrent-nox-static

		🟡 With Qbittorrent 4.4.0 onwards all cmake builds use Qt6 and all qmake builds use Qt5, as long as Qt5 is supported.

		🟡 Binary builds are stripped - See https://userdocs.github.io/qbittorrent-nox-static/#/debugging

		🟠 [To see the build combinations that the script automates please check the build table. for more info](https://github.com/userdocs/qbittorrent-nox-static#build-table---dependencies---arch---os---build-tools)

		<!--
		declare -A current_build_version
		current_build_version[openssl]="${app_version[openssl]}"
		current_build_version[boost]="${app_version[boost]}"
		current_build_version[libtorrent_${qbt_libtorrent_version//\./_}]="${app_version[libtorrent]}"
		current_build_version[qt${qt_version_short_array[0]}]="${app_version[qtbase]}"
		current_build_version[qbittorrent]="${app_version[qbittorrent]}"
		current_build_version[revision]="${qbt_revision_version:-0}"
		-->
	RELEASE_INFO
	echo "${github_tag[qbittorrent]}_${github_tag[libtorrent]}" > "${release_info_dir}/tag.md"
	echo "${qBittorrent_version} ${app_version[qbittorrent]} libtorrent ${app_version[libtorrent]}" > "${release_info_dir}/title.md"

	if [[ "${qBittorrent_version}" =~ Edition$ ]]; then
		echo "enhanced_${github_tag[qbittorrent]}_${github_tag[libtorrent]}" > "${release_info_dir}/tag.md"
	fi

	# if [[ "${qbt_skip_icu}" == "yes" ]]; then
	# 	sed -i 's/ICUI/This file does not contain icu/' "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md"
	# else
	# 	sed -i 's/^/icu-&/' "${release_info_dir}/tag.md"
	# 	sed -i '/libtorrent/s/$/& icu/' "${release_info_dir}/title.md"
	# 	sed -i '/ICUI/d' "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md"
	# fi
	return
}

# 这是第一个帮助部分，用于不需要任何处理并且在使用帮助时仅提供静态结果的触发器
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
					printf '\n%b\n\n' " ${urc} 删除缓存目录： ${clc}${qbt_cache_dir}${cend}"
					exit
				fi
				shift 3
			elif [[ -n "${3}" && ! "${3}" =~ ^- ]]; then
				printf '\n%b\n' " ${urc}仅支持 ${clb}bs${cend} 或 ${clb}rm${cend} 作为此开关的条件${cend}"
				printf '\n%b\n\n' " ${uyc} 参见 ${clb}-h-cd${cend} 获取更多信息${cend}"
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
				printf '\n%b\n\n' " ${urc}使用 ${cend} ${clb}-ma 时必须提供有效的 arch 选项${cend}"
				unset "multi_arch_options[default]"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${ulbc} ${arches}${cend}"
				done
				printf '\n%b\n\n' " ${ugc} 用法示例：${clb} -ma aarch64${cend}"
				exit 1
			fi
			;;
		-p | --proxy)
			qbt_git_proxy=("-c" "http.sslVerify=false" "-c" "http.https://github.com.proxy=${2}")
			qbt_curl_proxy=("--proxy-insecure" "-x" "${2}")
			shift 2
			;;
		-o | --optimize)
			qbt_optimize="-march=native"
			shift
			;;
		-s | --strip)
			qbt_optimise_strip="yes"
			shift
			;;
		-sdu | --script-debug-urls)
			script_debug_urls="yes"
			shift
			;;
		-wf | --workflow)
			qbt_workflow_files="yes"
			shift
			;;
		--) # 结束参数解析
			shift
			break
			;;
		*) # 保留位置参数
			params1+=("${1}")
			shift
			;;
	esac
done

# 在适当的位置设置位置参数。
set -- "${params1[@]}"

# 函数第 1 部分：使用我们的一些函数
_set_default_values "${@}"
[[ ! -e "${qbt_working_dir}/deps_installed" ]] && _check_dependencies
# _script_version
_test_url
_set_build_directory
_set_module_urls "${@}"

# 环境变量——设置flags的位置参数
[[ -n "${qbt_patches_url}" ]] && set -- -pr "${qbt_patches_url}" "${@}"
[[ -n "${qbt_boost_tag}" ]] && set -- -bt "${qbt_boost_tag}" "${@}"
[[ -n "${qbt_libtorrent_tag}" ]] && set -- -lt "${qbt_libtorrent_tag}" "${@}"
[[ -n "${qbt_qt_tag}" ]] && set -- -qtt "${qbt_qt_tag}" "${@}"
[[ -n "${qbt_qbittorrent_tag}" ]] && set -- -qt "${qbt_qbittorrent_tag}" "${@}"

# 此部分控制我们可以传递给脚本以修改某些变量和行为的标志。
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
				printf '\n%b\n\n' " ${urc} 使用${cend} ${clb}-ma${cend} 时必须提供有效的arch 选项"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${ulbc} ${arches}${cend}"
				done
				printf '\n%b\n\n' " ${ugc} 用法示例：${clb} -ma aarch64${cend}"
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
				if [[ "${app_version[boost]}" =~ \.beta ]]; then
					boost_url="${app_version[boost]//\./_}" boost_url="${boost_url/beta1/b1}" boost_url="${boost_url/beta2/b2}"
					source_archive_url[boost]="https://boostorg.jfrog.io/artifactory/main/beta/${app_version[boost]}/source/boost_${boost_url}.tar.gz"
				else
					source_archive_url[boost]="https://boostorg.jfrog.io/artifactory/main/release/${app_version[boost]}/source/boost_${app_version[boost]//\./_}.tar.gz"
				fi
				if ! _curl -I "${source_archive_url[boost]}" &> /dev/null; then
					source_default[libtorrent]="folder"
				fi
				qbt_workflow_override[boost]="yes"
				_test_git_ouput "${github_tag[boost]}" "boost" "${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${urc} ${cly}您必须为此开关提供标签：${cend} ${clb}${1} TAG${cend}"
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
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "${github_tag[qbittorrent]}")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_default[qbittorrent]="folder"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "${github_tag[qbittorrent]}"
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
				[[ "${github_tag[libtorrent]}" =~ ^RC_ ]] && app_version[libtorrent]="${github_tag[libtorrent]}"
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
				_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "$2"
				shift 2
			else
				printf '\n%b\n\n' " ${urc} ${cly}您必须为此开关提供标签：${cend} ${clb}${1} TAG${cend}"
				exit
			fi
			;;
		-pr | --patch-repo)
			if [[ -n "${2}" ]]; then
				if _curl "https://github.com/${2}" &> /dev/null; then
					qbt_patches_url="${2}"
				else
					printf '\n%b\n' " ${urc} ${cly}此 repo 不存在：${cend}"
					printf '\n%b\n' "   ${clc}https://github.com/${2}${cend}"
					printf '\n%b\n\n' " ${uyc} ${cly}请提供有效的用户名和存储库。${cend}"
					exit
				fi
				shift 2
			else
				printf '\n%b\n\n' " ${urc} ${cly}您必须为此开关提供标签：${cend} ${clb}${1} username/repo ${cend}"
				exit
			fi
			;;
		-qm | --qbittorrent-master)
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "${github_tag[qbittorrent]}")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${github_tag[qbittorrent]}.tar.gz"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "${github_tag[qbittorrent]}"
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
				printf '\n%b\n\n' " ${urc} ${cly}您必须为此开关提供标签：${cend} ${clb}${1} TAG${cend}"
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
				shift 2
			else
				printf '\n%b\n\n' " ${urc} ${cly}您必须为此开关提供标签：${cend} ${clb}${1} TAG ${cend}"
				exit
			fi
			;;
		-h | --help)
			printf '\n%b\n\n' " ${tb}${tu}这是可用选项的列表${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-b${cend}     ${td}或${cend} ${clb}--build-directory${cend}       ${cy}帮助：${cend} ${clb}-h-b${cend}     ${td}或${cend} ${clb}--help-build-directory${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bt${cend}    ${td}或${cend} ${clb}--boost-version${cend}         ${cy}帮助：${cend} ${clb}-h-bt${cend}    ${td}或${cend} ${clb}--help-boost-version${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-c${cend}     ${td}或${cend} ${clb}--cmake${cend}                 ${cy}帮助：${cend} ${clb}-h-c${cend}     ${td}或${cend} ${clb}--help-cmake${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-cd${cend}    ${td}或${cend} ${clb}--cache-directory${cend}       ${cy}帮助：${cend} ${clb}-h-cd${cend}    ${td}或${cend} ${clb}--help-cache-directory${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-d${cend}     ${td}或${cend} ${clb}--debug${cend}                 ${cy}帮助：${cend} ${clb}-h-d${cend}     ${td}或${cend} ${clb}--help-debug${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bs-p${cend}  ${td}或${cend} ${clb}--boot-strap-patches${cend}    ${cy}帮助：${cend} ${clb}-h-bs-p${cend}  ${td}或${cend} ${clb}--help-boot-strap-patches${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bs-c${cend}  ${td}或${cend} ${clb}--boot-strap-cmake${cend}      ${cy}帮助：${cend} ${clb}-h-bs-c${cend}  ${td}或${cend} ${clb}--help-boot-strap-cmake${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bs-r${cend}  ${td}或${cend} ${clb}--boot-strap-release${cend}    ${cy}帮助：${cend} ${clb}-h-bs-r${cend}  ${td}或${cend} ${clb}--help-boot-strap-release${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bs-ma${cend} ${td}或${cend} ${clb}--boot-strap-multi-arch${cend} ${cy}帮助：${cend} ${clb}-h-bs-ma${cend} ${td}或${cend} ${clb}--help-boot-strap-multi-arch${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-bs-a${cend}  ${td}或${cend} ${clb}--boot-strap-all${cend}        ${cy}帮助：${cend} ${clb}-h-bs-a${cend}  ${td}或${cend} ${clb}--help-boot-strap-all${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-i${cend}     ${td}或${cend} ${clb}--icu${cend}                   ${cy}帮助：${cend} ${clb}-h-i${cend}     ${td}或${cend} ${clb}--help-icu${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-lm${cend}    ${td}或${cend} ${clb}--libtorrent-master${cend}     ${cy}帮助：${cend} ${clb}-h-lm${cend}    ${td}或${cend} ${clb}--help-libtorrent-master${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-lt${cend}    ${td}或${cend} ${clb}--libtorrent-tag${cend}        ${cy}帮助：${cend} ${clb}-h-lt${cend}    ${td}或${cend} ${clb}--help-libtorrent-tag${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-m${cend}     ${td}或${cend} ${clb}--master${cend}                ${cy}帮助：${cend} ${clb}-h-m${cend}     ${td}或${cend} ${clb}--help-master${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-ma${cend}    ${td}或${cend} ${clb}--multi-arch${cend}            ${cy}帮助：${cend} ${clb}-h-ma${cend}    ${td}或${cend} ${clb}--help-multi-arch${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-n${cend}     ${td}或${cend} ${clb}--no-delete${cend}             ${cy}帮助：${cend} ${clb}-h-n${cend}     ${td}或${cend} ${clb}--help-no-delete${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-o${cend}     ${td}或${cend} ${clb}--optimize${cend}              ${cy}帮助：${cend} ${clb}-h-o${cend}     ${td}或${cend} ${clb}--help-optimize${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-p${cend}     ${td}或${cend} ${clb}--proxy${cend}                 ${cy}帮助：${cend} ${clb}-h-p${cend}     ${td}或${cend} ${clb}--help-proxy${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-pr${cend}    ${td}或${cend} ${clb}--patch-repo${cend}            ${cy}帮助：${cend} ${clb}-h-pr${cend}    ${td}或${cend} ${clb}--help-patch-repo${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-qm${cend}    ${td}或${cend} ${clb}--qbittorrent-master${cend}    ${cy}帮助：${cend} ${clb}-h-qm${cend}    ${td}或${cend} ${clb}--help-qbittorrent-master${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-qt${cend}    ${td}或${cend} ${clb}--qbittorrent-tag${cend}       ${cy}帮助：${cend} ${clb}-h-qt${cend}    ${td}或${cend} ${clb}--help-qbittorrent-tag${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-qtt${cend}   ${td}或${cend} ${clb}--qt-tag${cend}                ${cy}帮助：${cend} ${clb}-h-qtt${cend}   ${td}或${cend} ${clb}--help-qtt-tag${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-s${cend}     ${td}或${cend} ${clb}--strip${cend}                 ${cy}帮助：${cend} ${clb}-h-s${cend}     ${td}或${cend} ${clb}--help-strip${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-sdu${cend}   ${td}或${cend} ${clb}--script-debug-urls${cend}     ${cy}帮助：${cend} ${clb}-h-sdu${cend}   ${td}或${cend} ${clb}--help-script-debug-urls${cend}"
			printf '%b\n' " ${cg}使用：${cend} ${clb}-wf${cend}    ${td}或${cend} ${clb}--workflow${cend}              ${cy}帮助：${cend} ${clb}-h-wf${cend}    ${td}或${cend} ${clb}--help-workflow${cend}"
			printf '\n%b\n' " ${tb}${tu}特定于模块的帮助 - 标志用于此处列出的模块。${cend}"
			printf '\n%b\n' " ${cg}使用：${cend} ${clm}all${cend} ${td}或${cend} ${clm}module-name${cend}          ${cg}用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clm}all${cend} ${clb}-i${cend}"
			printf '\n%b\n' " ${td}${clm}all${cend} ${td}----------------${cend} ${td}${cly}optional${cend} ${td}安装所有模块的推荐方法${cend}"
			printf '%b\n' " ${td}${clm}install${cend} ${td}------------${cend} ${td}${cly}optional${cend} ${td}Install the ${td}${clc}${qbt_install_dir_short}/completed/qbittorrent-nox${cend} ${td}binary${cend}"
			[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && printf '%b\n' " ${td}${clm}glibc${cend} ${td}--------------${cend} ${td}${clr}required${cend} ${td}本地编译libc静态链接nss${cend}"
			printf '%b\n' " ${td}${clm}zlib${cend} ${td}---------------${cend} ${td}${clr}required${cend} ${td}在本地编译 zlib${cend}"
			printf '%b\n' " ${td}${clm}iconv${cend} ${td}--------------${cend} ${td}${clr}required${cend} ${td}在本地编译 iconv${cend}"
			printf '%b\n' " ${td}${clm}icu${cend} ${td}----------------${cend} ${td}${cly}optional${cend} ${td}在本地编译 ICU${cend}"
			printf '%b\n' " ${td}${clm}openssl${cend} ${td}------------${cend} ${td}${clr}required${cend} ${td}在本地编译 openssl${cend}"
			printf '%b\n' " ${td}${clm}boost${cend} ${td}--------------${cend} ${td}${clr}required${cend} ${td}下载、提取和编译 boost 库文件${cend}"
			printf '%b\n' " ${td}${clm}libtorrent${cend} ${td}---------${cend} ${td}${clr}required${cend} ${td}在本地编译 libtorrent${cend}"
			printf '%b\n' " ${td}${clm}双转换${cend} ${td}--${cend} ${td}${clr}required${cend} ${td}cmakke + Qt6 仅在现代操作系统上编译组件。${cend}"
			printf '%b\n' " ${td}${clm}qtbase${cend} ${td}-------------${cend} ${td}${clr}required${cend} ${td}本地编译qtbase${cend}"
			printf '%b\n' " ${td}${clm}qttools${cend} ${td}------------${cend} ${td}${clr}required${cend} ${td}在本地编译 qttools${cend}"
			printf '%b\n' " ${td}${clm}qbittorrent${cend} ${td}--------${cend} ${td}${clr}需要${cend} ${td}在本地编译 qbittorrent${cend}"
			printf '\n%b\n' " ${tb}${tu}env 帮助 - 支持的可导出环境变量${cend}"
			printf '\n%b\n' " ${td}${clm}export qbt_libtorrent_version=\"\"${cend} ${td}--------${cend} ${td}${clr}options${cend} ${td}1.2 - 2.0${cend}"
			printf '%b\n' " ${td}${clm}export qbt_qt_version=\"\"${cend} ${td}----------------${cend} ${td}${clr}options${cend} ${td}5 - 5.15 - 6 - 6.2 - 6.3 等等${cend}"
			printf '%b\n' " ${td}${clm}export qbt_build_tool=\"\"${cend} ${td}----------------${cend} ${td}${clr}options${cend} ${td}qmake - cmake${cend}"
			printf '%b\n' " ${td}${clm}export qbt_cross_name=\"\"${cend} ${td}----------------${cend} ${td}${clr}options${cend} ${td}x86_64 - aarch64 - armv7 - armhf${cend}"
			printf '%b\n' " ${td}${clm}export qbt_patches_url=\"\"${cend} ${td}---------------${cend} ${td}${clr}options${cend} ${td}userdocs/qbittorrent-nox-static.${cend}"
			printf '%b\n' " ${td}${clm}export qbt_libtorrent_tag=\"\"${cend} ${td}------------${cend} ${td}${clr}options${cend} ${td}为 libtorrent 获取有效的 git 标签或分支${cend}"
			printf '%b\n' " ${td}${clm}export qbt_qbittorrent_tag=\"\"${cend} ${td}-----------${cend} ${td}${clr}options${cend} ${td}为 qbittorrent 使用有效的 git 标签或分支${cend}"
			printf '%b\n' " ${td}${clm}export qbt_boost_tag=\"\"${cend} ${td}-----------------${cend} ${td}${clr}options${cend} ${td}采用有效的 git 标签或分支进行提升${cend}"
			printf '%b\n' " ${td}${clm}export qbt_qt_tag=\"\"${cend} ${td}--------------------${cend} ${td}${clr}options${cend} ${td}为 Qt 获取有效的 git 标签或分支${cend}"
			printf '%b\n' " ${td}${clm}export qbt_workflow_files=\"\"${cend} ${td}------------${cend} ${td}${clr}options${cend} ${td}是 否 - 使用 qbt-workflow-files 作为依赖项${cend}"
			printf '%b\n' " ${td}${clm}export qbt_workflow_artifacts=\"\"${cend} ${td}--------${cend} ${td}${clr}options${cend} ${td}是 否 - 使用 qbt_workflow_artifacts 作为依赖项${cend}"
			printf '%b\n' " ${td}${clm}export qbt_cache_dir=\"\"${cend} ${td}-----------------${cend} ${td}${clr}options${cend} ${td}路径为空 - 提供缓存目录的路径${cend}"
			printf '%b\n' " ${td}${clm}export qbt_libtorrent_master_jamfile=\"\"${cend} ${td}-${cend} ${td}${clr}options${cend} ${td}是 否 - 使用 RC 分支而不是发布 jamfile${cend}"
			printf '%b\n' " ${td}${clm}export qbt_optimise_strip=\"\"${cend} ${td}------------${cend} ${td}${clr}options${cend} ${td}是 否 - 剥离二进制文件 - 不能与调试一起使用${cend}"
			printf '%b\n' " ${td}${clm}export qbt_build_debug=\"\"${cend} ${td}---------------${cend} ${td}${clr}options${cend} ${td}是 否 - 调试编译 - 不能与 strip 一起使用${cend}"
			_print_env
			exit
			;;
		-h-b | --help-build-directory)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 默认编译位置： ${cc}${qbt_install_dir_short}${cend}"
			printf '\n%b\n' " ${clb}-b${cend} or ${clb}--build-directory${cend} 设置编译目录的位置。"
			printf '\n%b\n' " ${cy}路径是相对于脚本位置的。我建议您使用完整路径。${cend}"
			printf '\n%b\n' " ${td}${ulbc} 使用示例：${cend} ${td}${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}all${cend} ${td}- 将安装所有模块并将 libtorrent 编译到默认编译位置${cend}"
			printf '\n%b\n' " ${td}${ulbc} 使用示例：${cend} ${td}${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}module${cend} ${td}- 将单个模块安装到默认编译位置${cend}"
			printf '\n%b\n\n' " ${td}${ulbc} 使用示例：${cend} ${td}${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}module${cend} ${clb}-b${cend} ${td}${clc}\"\$HOME/build\"${cend} ${td}- 将指定一个自定义编译目录并将特定模块安装到该自定义位置${cend}"
			exit
			;;
		-h-bs-p | --help-boot-strap-patches)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 以此结构创建目录： ${cc}${qbt_install_dir_short}/patches/app_name/tag/patch${cend}"
			printf '\n%b\n' " 例如，在那里添加你的补丁。"
			printf '\n%b\n' " ${cc}${qbt_install_dir_short}/patches/libtorrent/${app_version[libtorrent]}/patch${cend}"
			printf '\n%b\n\n' " ${cc}${qbt_install_dir_short}/patches/qbittorrent/${app_version[qbittorrent]}/patch${cend}"
			exit
			;;
		-h-bs-c | --help-boot-cmake)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 此引导程序会将 cmake 和 ninja build 安装到编译目录"
			printf '\n%b\n\n'"${clg} 用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs-c${cend}"
			exit
			;;
		-h-bs-r | --help-boot-strap-release)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' "${clr} Github 操作特定。你可能不需要它${cend}"
			printf '\n%b\n' " 此开关在此目录中创建一些 github 发布模板文件"
			printf '\n%b\n' " ${qbt_install_dir_short}/release_info"
			printf '\n%b\n\n' "${clg} 用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs-r${cend}"
			exit
			;;
		-h-bs-ma | --help-boot-strap-multi-arch)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${urc}${clr} Github 动作和 ALpine 特定。你可能不需要它${cend}"
			printf '\n%b\n' " 此开关引导任何提供和支持的体系结构所需的 musl 交叉编译文件"
			printf '\n%b\n' " ${uyc} armhf"
			printf '%b\n' " ${uyc} armv7"
			printf '%b\n' " ${uyc} aarch64"
			printf '\n%b\n' "${clg} 用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs-ma ${qbt_cross_name:-aarch64}${cend}"
			printf '\n%b\n\n' " ${uyc} 您也可以将其设置为触发交叉编译的变量：${clb}export qbt_cross_name=${qbt_cross_name:-aarch64}${cend}"
			exit
			;;
		-h-bs-a | --help-boot-strap-all)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${urc}${clr} 特定于 Github 操作且仅适用于 Apine。你可能不需要它${cend}"
			printf '\n%b\n' " 执行所有引导选项"
			printf '\n%b\n' "${clg} 用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs-a${cend}"
			printf '\n%b\n' " ${uyc} ${cly}补丁${cend}"
			printf '%b\n' " ${uyc} ${cly}发布信息${cend}"
			printf '%b\n' " ${uyc} ${cly}Cmake 和 ninja 编译 ${cend} 如果 ${clb}-c${cend} 标志被传递"
			printf '%b\n' " ${uyc} ${cly}如果传递了 ${clb}-ma${cend} 标志，则多 arch${cend}"
			printf '\n%b\n' " 相当于做： ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs -bs-r${cend}"
			printf '\n%b\n\n' " 并使用 ${clb}-c${cend} 和 ${clb}-ma${cend} : ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs -bs-c -bs-ma -bs-r ${cend}"
			exit
			;;
		-h-bt | --help-boost-version)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 这将使您可以设置特定版本的 boost 以与较旧的编译组合一起使用"
			printf '\n%b\n' " ${ulbc} 使用示例： ${clb}-bt boost-1.81.0${cend}"
			printf '\n%b\n\n' " ${ulbc} 使用示例： ${clb}-bt boost-1.82.0.beta1${cend}"
			exit
			;;
		-h-c | --help-cmake)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 这个标志可以通过几种方式改变编译过程。"
			printf '\n%b\n' " ${uyc} 使用 cmake 编译 libtorrent。"
			printf '%b\n' " ${uyc} 使用 cmake 编译 qbittorrent。"
			printf '\n%b\n\n' " ${uyc} 您可以将此标志与 ICU 一起使用，qtbase 将使用 ICU 而不是 iconv。"
			exit
			;;
		-h-cd | --help-cache-directory)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 这将让你设置一个目录的路径，其中包含模块的缓存 github repos"
			printf '\n%b\n' " ${uyc} 缓存的应用程序文件夹名称必须与模块名称匹配。大小写和拼写"
			printf '\n%b\n' " For example: ${clc}~/cache_dir/qbittorrent${cend}"
			printf '\n%b\n' " 支持的附加标志：${clc}rm${cend} - 删除缓存目录并退出"
			printf '\n%b\n' " 支持的附加标志：${clc}bs${cend} - 下载所有激活模块的缓存然后退出"
			printf '\n%b\n' " ${ulbc} 使用示例： ${clb}-cd ~/cache_dir${cend}"
			printf '\n%b\n' " ${ulbc} 使用示例： ${clb}-cd ~/cache_dir rm${cend}"
			printf '\n%b\n\n' " ${ulbc} 使用示例： ${clb}-cd ~/cache_dir bs${cend}"
			exit
			;;
		-h-d | --help-debug)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n\n' " 编译时为 libtorrent 和 qbitorrent 启用调试符号 - gdb 回溯需要"
			exit
			;;
		-h-n | --help-no-delete)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 跳过选定模块的所有删除功能以留下源代码目录。"
			printf '\n%b\n' " ${td}如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译${cend}"
			printf '\n%b\n\n' " ${clb}-n${cend}"
			exit
			;;
		-h-i | --help-icu)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 编译 qBittorrent 时使用 ICU 库。最终的二进制文件大小约为 ~50Mb"
			printf '\n%b\n' " ${td}如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译${cend}"
			printf '\n%b\n\n' " ${clb}-i${cend}"
			exit
			;;
		-h-m | --help-master)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${cg}libtorrent 始终使用 master 分支 RC_${qbt_libtorrent_version//./_}${cend}"
			printf '\n%b\n' " ${cg}qBittorrent 始终使用 master 分支"
			printf '\n%b\n' " ${td}如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译${cend}"
			printf '\n%b\n\n' " ${clb}-lm${cend}"
			exit
			;;
		-h-ma | --help-multi-arch)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${urc}${clr} Github 动作和 ALpine 特定。你可能不需要它${cend}"
			printf '\n%b\n' " 此开关将使脚本对这些受支持的体系结构使用交叉编译配置"
			printf '\n%b\n' " ${uyc} armhf"
			printf '%b\n' " ${uyc} armv7"
			printf '%b\n' " ${uyc} aarch64"
			printf '\n%b\n' "${clg} 用法：${cend} ${clc}${qbt_working_dir_short}/$(basename -- "$0")${cend} ${clb}-bs-ma ${qbt_cross_name:-aarch64}${cend}"
			printf '\n%b\n\n' " ${uyc} 您也可以将其设置为触发交叉编译的变量：${clb}export qbt_cross_name=${qbt_cross_name:-aarch64}${cend}"
			exit
			;;
		-h-lm | --help-libtorrent-master)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " Always use the master branch for ${cg}libtorrent-${qbt_libtorrent_version}${cend}"
			printf '\n%b\n' " This master that will be used is: ${cg}RC_${qbt_libtorrent_version//./_}${cend}"
			printf '\n%b\n' " ${td}如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译${cend}"
			printf '\n%b\n\n' " ${clb}-lm${cend}"
			exit
			;;
		-h-lt | --help-libtorrent-tag)
			if [[ ! "${github_tag[libtorrent]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
				printf '\n%b\n' " 从 github 克隆时使用提供的 libtorrent 标签。"
				printf '\n%b\n' " ${cy}如果在帮助选项之前调用，您可以将此标志与此帮助命令一起使用以查看值。${cend}"
				printf '\n%b\n' " ${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend}${clb} -lt ${clc}${github_tag[libtorrent]}${cend} ${clb}-h-lt${cend}"
				printf '\n%b\n' " ${td}该标志必须与参数一起提供。${cend}"
				printf '\n%b\n' " ${clb}-lt${cend} ${clc}${github_tag[libtorrent]}${cend}"
			fi
			printf '\n'
			exit
			;;
		-h-o | --help-optimize)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${uyc} ${cly}警告：${cend} 使用此标志将意味着您的静态编译受限于与主机规范匹配的 CPU"
			printf '\n%b\n' " ${ulbc} 使用示例： ${clb}-o${cend}"
			printf '\n%b\n\n' " 使用的附加标志： ${clc}-march=native${cend}"
			exit
			;;
		-h-p | --help-proxy)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 指定代理 URL 和 PORT 以与 curl 和 git 一起使用"
			printf '\n%b\n' " ${ulbc} 使用示例："
			printf '\n%b\n' " ${clb}-p${cend} ${clc}username:password@https://123.456.789.321:8443${cend}"
			printf '\n%b\n' " ${clb}-p${cend} ${clc}https://proxy.com:12345${cend}"
			printf '\n%b\n' " ${uyc} 在帮助选项之前调用它以动态查看结果："
			printf '\n%b\n\n' " ${clb}-p${cend} ${clc}https://proxy.com:12345${cend} ${clb}-h-p${cend}"
			[[ -n "${qbt_curl_proxy[*]}" ]] && printf '%b\n' " 代理命令: ${clc}${qbt_curl_proxy[*]}${tn}${cend}"
			exit
			;;
		-h-pr | --help-patch-repo)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 指定用户名和存储库以使用托管在 github 上的补丁${cend}"
			printf '\n%b\n' " ${uyc} ${cly}您需要使用此标志使用特定的 github 目录格式${cend}"
			printf '\n%b\n' " ${clc}patches/libtorrent/${app_version[libtorrent]}/patch${cend}"
			printf '%b\n' " ${clc}patches/libtorrent/${app_version[libtorrent]}/Jamfile${cend} ${clr}(默认为分支主机)${cend}"
			printf '\n%b\n' " ${clc}patches/qbittorrent/${app_version[qbittorrent]}/patch${cend}"
			printf '\n%b\n' " ${uyc} ${cly}如果安装标签与托管标签补丁文件相匹配，它将被自动使用。${cend}"
			printf '\n%b\n' " 标签名称将始终是默认或特定标签的缩写版本。${cend}"
			printf '\n%b\n\n' " ${ulbc} ${cg}使用示例：${cend} ${clb}-pr usnerame/repo${cend}"
			exit
			;;
		-h-qm | --help-qbittorrent-master)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${cg}qBittorrent 始终使用 master 分支${cend}"
			printf '\n%b\n' " 将要使用的主控是：${cg}master${cend}"
			printf '\n%b\n' " ${td}此标志不带任何参数。${cend}"
			printf '\n%b\n\n' " ${clb}-qm${cend}"
			exit
			;;
		-h-qt | --help-qbittorrent-tag)
			if [[ ! "${github_tag[qbittorrent]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
				printf '\n%b\n' " 从 github 克隆时使用提供的 qBittorrent 标签。"
				printf '\n%b\n' " ${cy}如果在帮助选项之前调用，您可以将此标志与此帮助命令一起使用以查看值。${cend}"
				printf '\n%b\n' " ${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend}${clb} -qt ${clc}${github_tag[qbittorrent]}${cend} ${clb}-h-qt${cend}"
				printf '\n%b\n' " ${td}该标志必须与参数一起提供。${cend}"
				printf '\n%b\n' " ${clb}-qt${cend} ${clc}${github_tag[qbittorrent]}${cend}"
			fi
			printf '\n'
			exit
			;;
		-h-qtt | --help-qt-tag)
			if [[ ! "${github_tag[qtbase]}" =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
				printf '\n%b\n' " 从 github 克隆时使用提供的 Qt 标签。"
				printf '\n%b\n' " ${cy}如果在帮助选项之前调用，您可以将此标志与此帮助命令一起使用以查看值。${cend}"
				printf '\n%b\n' " ${cg}${qbt_working_dir_short}/$(basename -- "$0")${cend}${clb} -qt ${clc}${github_tag[qtbase]}${cend} ${clb}-h-qt${cend}"
				printf '\n%b\n' " ${td}该标志必须与参数一起提供。${cend}"
				printf '\n%b\n' " ${clb}-qt${cend} ${clc}${github_tag[qtbase]}${cend}"
			fi
			printf '\n'
			exit
			;;
		-h-s | --help-strip)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " 去除不需要符号的 qbittorrent-nox 二进制文件以减小文件大小"
			printf '\n%b\n' " ${uyc} 静态 musl 编译不适用于在堆栈跟踪中编译的 qBittorrents。"
			printf '\n%b\n' " 如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译 ${clb}-d${cend}"
			printf '\n%b\n' " ${td}如果您需要使用 gdb 调试编译，则必须使用标志编译调试编译${cend}"
			printf '\n%b\n\n' " ${clb}-s${cend}"
			exit
			;;
		-h-sdu | --help-script-debug-urls)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${ulbc} 这将打印出所有 ${cly}_set_module_urls${cend} 数组信息以检查"
			printf '\n%b\n\n' " ${ulbc} 使用示例： ${clb}-sdu${cend}"
			exit
			;;
		-h-wf | --help-workflow)
			printf '\n%b\n' " ${ulcc} ${tb}${tu}这是此标志的帮助说明：${cend}"
			printf '\n%b\n' " ${uyc} 使用来自的档案${clc}https://github.com/userdocs/qbt-workflow-files/releases/latest${cend}"
			printf '\n%b\n' " ${uyc} ${cly}警告：${cend} 如果您为受支持的模块设置自定义版本，它将覆盖并禁用工作流作为该模块的源"
			printf '\n%b\n\n' " ${ulbc} 使用示例： ${clb}-wf${cend}"
			exit
			;;
		--) # 结束参数解析
			shift
			break
			;;
		-*) # 不支持的标志
			printf '\n%b\n\n' " ${urc}错误：不支持的标志 ${clr}${1}${cend} - 使用 ${clg}-h${cend} 或 ${clg}--help${cend} 查看有效选项${cend}" >&2
			exit 1
			;;
		*) # 保留位置参数
			params2+=("${1}")
			shift
			;;
	esac
done
set -- "${params2[@]}" # 在适当的位置设置位置参数。

# 函数第 2 部分：使用我们的一些函数
[[ "${1}" == "install" ]] && _install_qbittorrent "${@}" # see functions

# 如果我们发现任何 github 标签验证失败或 url 无效，现在让我们退出
_error_tag

# 函数第 3 部分：任何需要将上述选项中的参数 while 循环移位的函数都必须在此行之后
_debug "${@}"                # requires shifted params from options block 2
_installation_modules "${@}" # requires shifted params from options block 2

# 如果任何模块未通过 qbt_modules_test，则立即退出。
if [[ "${qbt_modules_test}" == 'fail' || "${#}" -eq '0' ]]; then
	# printf '\n%b\n' " ${tbk}${urc}${cend}${tb} 不支持提供的一个或多个模块${cend}"
	printf '\n%b\n' " ${uyc}${tb} 以下是要安装的模块列表${cend}"
	printf '%b\n' " ${umc}${clm} ${qbt_modules[*]}${cend}"
	_print_env
	exit
fi

# 函数第 4 部分：
[[ ! -e "${qbt_working_dir}/cmake_ninja" ]] && _cmake
_multi_arch

_glibc_bootstrap() {
	sub_dir="/BUILD"
}

_glibc() {
	"${qbt_dl_folder_path}/configure" "${multi_glibc[@]}" --prefix="${qbt_install_dir}" --enable-static-nss --disable-nscd --srcdir="${qbt_dl_folder_path}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/$app_name.log"
	_post_command build
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"

	unset sub_dir
}

_zlib() {
	if [[ "${qbt_build_tool}" == "cmake" ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		# force set some ARCH when using zlib-ng, cmake and musl-cross since it does detect the arch correctly.
		[[ "${qbt_cross_target}" =~ ^(alpine)$ ]] && printf '%b\n' "\narchfound ${qbt_zlib_arch:-x86_64}" >> "${qbt_dl_folder_path}/cmake/detect-arch.c"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_CXX_STANDARD="${standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D ZLIB_COMPAT=ON \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		# 在使用 zlib-ng、configure 和 musl-cross 时强制设置一些 ARCH，因为它确实能正确检测到 arch。
		[[ "${qbt_cross_target}" =~ ^(alpine)$ ]] && sed "s|  CFLAGS=\"-O2 \${CFLAGS}\"|  ARCH=${qbt_zlib_arch:-x86_64}\n  CFLAGS=\"-O2 \${CFLAGS}\"|g" -i "${qbt_dl_folder_path}/configure"
		./configure --prefix="${qbt_install_dir}" --static --zlib-compat |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi
}

_iconv() {
	if [[ -n "${qbt_cache_dir}" && -d "${qbt_cache_dir}/${app_name}" ]]; then
		./gitsub.sh pull --depth 1
		./autogen.sh
	fi

	./configure "${multi_iconv[@]}" --prefix="${qbt_install_dir}" --disable-shared --enable-static CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}

_icu_bootstrap() {
	if [[ -n "${qbt_cache_dir}" && -d "${qbt_cache_dir}/${app_name}" && "${qbt_workflow_files}" == "no" ]]; then
		sub_dir="/icu4c/source"
	else
		sub_dir="/source"
	fi
}

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

_openssl() {
	"${multi_openssl[@]}" --prefix="${qbt_install_dir}" --libdir="${lib_dir}" --openssldir="/etc/ssl" threads no-shared no-dso no-comp CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	make install_sw |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}

_boost_bootstrap() {
	# 如果使用源文件并且 jfrog 失败，默认为 git，如果我们不使用工作流源。
	if [[ "${boost_url_status}" =~ (403|404) && "${qbt_workflow_files}" == "no" && "${qbt_workflow_artifacts}" == "no" ]]; then
		source_default["${app_name}"]="folder"
	fi
}

_boost() {
	if [[ "${source_default["${app_name}"]}" == "file" ]]; then
		mv -f "${qbt_dl_folder_path}/" "${qbt_install_dir}/boost"
		_pushd "${qbt_install_dir}/boost"
	fi

	if [[ "${qbt_build_tool}" != 'cmake' ]]; then
		"${qbt_install_dir}/boost/bootstrap.sh" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		ln -s "${qbt_install_dir}/boost/boost" "${qbt_install_dir}/boost/include"
	else
		printf '%b\n' " ${uyc} 跳过 b2，因为我们在 Qt6 中使用 cmake"
	fi

	if [[ "${source_default["${app_name}"]}" == "folder" ]]; then
		"${qbt_install_dir}/boost/b2" headers |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	fi
}

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
			-D CMAKE_CXX_STANDARD="${standard}" \
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
		# 检查克隆的 libtorrent 的实际版本而不是使用标签，以便我们可以在使用自定义 pr 分支时确定 RC_1_1、RC_1_2 或 RC_2_0。这将始终给出准确的结果。
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

		"${qbt_install_dir}/boost/b2" "${multi_libtorrent[@]}" -j"$(nproc)" "${lt_version_options[@]}" address-model="${bitness:-$(getconf LONG_BIT)}" "${qbt_libtorrent_debug}" optimization=speed cxxstd="${standard}" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static cxxflags="${CXXFLAGS}" cflags="${CPPFLAGS}" linkflags="${LDFLAGS}" install --prefix="${qbt_install_dir}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
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
			-D CMAKE_CXX_STANDARD="${standard}" \
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
		# 修复 5.15.4 以在 gcc 11 上编译
		sed '/^#  include <utility>/a #  include <limits>' -i "src/corelib/global/qglobal.h"
		# 不要通过禁用这些选项来默认剥离。我们将其默认设置为关闭并使用开关
		printf '%b\n' "CONFIG                 += ${qbt_strip_qmake}" >> "mkspecs/common/linux.conf"
		./configure "${multi_qtbase[@]}" -prefix "${qbt_install_dir}" "${icu[@]}" -opensource -confirm-license -release \
			-openssl-linked -static -c++std "${cxx_standard}" -qt-pcre \
			-no-feature-glib -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples \
			-skip tests -nomake tests -skip examples -nomake examples \
			-I "${include_dir}" -L "${lib_dir}" QMAKE_LFLAGS="${LDFLAGS}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${urc} 请使用正确的 qt 和编译工具组合"
		printf '\n%b\n\n' " ${urc} ${ugc} qt5 + qmake ${ugc} qt6 + cmake ${urc} qt5 + cmake ${urc} qt6 + qmake"
		exit 1
	fi
}

_qttools() {
	if [[ "${qbt_build_tool}" == 'cmake' && "${qbt_qt_version}" =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_libtorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="release" \
			-D CMAKE_CXX_STANDARD="${standard}" \
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
		"${qbt_install_dir}/bin/qmake" QMAKE_CXXFLAGS="-std=${cxx_standard} -static -w -fpermissive" QMAKE_LFLAGS="-static" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${urc} 请使用正确的 qt 和编译工具组合"
		printf '\n%b\n' " ${urc} ${ugc} qt5 + qmake ${ugc} qt6 + cmake ${urc} qt5 + cmake ${urc} qt6 + qmake"
		exit 1
	fi
}

_qbittorrent() {
	[[ "${what_id}" =~ ^(alpine)$ ]] && stacktrace="OFF"

	if [[ "${qbt_build_tool}" == 'cmake' ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_qbittorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="release" \
			-D QT6="${qbt_use_qt6}" \
			-D STACKTRACE="${stacktrace:-ON}" \
			-D CMAKE_CXX_STANDARD="${standard}" \
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

	if [[ -f "${qbt_install_dir}/bin/qbittorrent-nox" ]]; then
		mv "${qbt_install_dir}/bin/qbittorrent-nox" "${qbt_install_dir}/completed/${qbt_cross_name}-qt${qbt_qt_version}-${qBittorrent_version}-nox"
	fi
}

# 模块安装程序循环。这将遍历激活的模块并通过相应的功能安装它们
for app_name in "${qbt_modules[@]}"; do
	if [[ "${qbt_cache_dir_options}" != "bs" ]] && [[ ! -d "${qbt_install_dir}/boost" && "${app_name}" =~ (libtorrent|qbittorrent) ]]; then
		printf '\n%b\n\n' " ${urc}${clr} 警告 ${cend} 这个模块依赖于 boost 模块。一起使用它们：${clm} boost ${app_name}${cend}"
	else
		if [[ "${skip_modules["${app_name}"]}" == "no" ]]; then
			skipped_false=$((skipped_false + 1))
			if command -v "_${app_name}_bootstrap" &> /dev/null; then
				"_${app_name}_bootstrap"
			fi

			if [[ "${app_name}" =~ (glibc|iconv|icu) ]]; then
				_custom_flags_reset
			else
				_custom_flags_set
			fi
			_download
			[[ "${qbt_cache_dir_options}" == "bs" && "${skipped_false}" -eq "${#qbt_modules[@]}" ]] && printf '\n'
			[[ "${qbt_cache_dir_options}" == "bs" ]] && continue

			_apply_patches
			"_${app_name}"
			_fix_static_links
			[[ "${app_name}" != "boost" ]] && _delete_function
			[[ -f "${qbt_install_dir}/logs/${app_name}.log" ]] && cp -f "${qbt_install_dir}/logs/${app_name}.log" "${release_info_dir}/"
			if [[ "${app_name}" == "qbittorrent" ]]; then
				_pushd "${release_info_dir}"
				mv -v -- * "${qbt_install_dir}/completed/"
			fi
		fi

		if [[ "${#qbt_modules_skipped[@]}" -gt '0' ]]; then
			printf '\n'
			printf '%b' " ${ulmc} 当前的任务进度:"
			for skipped_true in "${qbt_modules_skipped[@]}"; do
				printf '%b' " ${clc}${skipped_true}${cend}"
			done
			printf '\n'
		fi
		[[ "${skipped_false}" -eq "${#qbt_modules[@]}" ]] && printf '\n'
	fi
	_pushd "${qbt_working_dir}"
done

exit
