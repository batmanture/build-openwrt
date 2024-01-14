#!/bin/bash
#================================================================================================
# 该文件根据GNU通用公共许可证第2版的条款授权。该程序以"原样"提供，没有任何明示或暗示的担保。
#
# 该文件是make OpenWrt的一部分
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# 描述：创建Docker镜像
# 版权所有（C）2021〜 https://github.com/unifreq/openwrt_packit
# 版权所有（C）2021〜 https://github.com/ophub/amlogic-s9xxx-openwrt
#
# 命令：./config/docker/make_docker_image.sh
#
#======================================== 函数列表 ========================================
# 函数：error_msg
# 输出错误消息并退出脚本
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# 函数：check_depends
# 检查依赖项并安装缺失的软件包
check_depends() {
    is_dpkg="0"
    dpkg_packages=("tar" "gzip")
    for package in "${dpkg_packages[@]}"; do
        [[ -n "$(dpkg -l | awk '{print $2}' | grep -w "^${package}$" 2>/dev/null)" ]] || is_dpkg="1"
    done

    if [[ "${is_dpkg}" -eq "1" ]]; then
        echo -e "${STEPS} 开始安装必要的依赖项..."
        sudo apt-get update
        sudo apt-get install -y "${dpkg_packages[@]}"
        [[ "${?}" -ne "0" ]] && error_msg "依赖项安装失败。"
    fi
}

# 函数：find_openwrt
# 查找OpenWrt文件（openwrt/*rootfs.tar.gz）并检查Dockerfile是否存在
find_openwrt() {
    cd "${current_path}"
    echo -e "${STEPS} 开始搜索OpenWrt文件..."

    openwrt_file_name="$(ls "${openwrt_path}/${openwrt_rootfs_file}" 2>/dev/null | head -n 1 | awk -F "/" '{print $NF}')"
    if [[ -n "${openwrt_file_name}" ]]; then
        echo -e "${INFO} OpenWrt文件: [ ${openwrt_file_name} ]"
    else
        error_msg "在 [ ${openwrt_path} ] 目录中没有 [ ${openwrt_rootfs_file} ] 文件。"
    fi

    [[ -f "${docker_path}/Dockerfile" ]] || error_msg "缺少Dockerfile。"
}

# 函数：adjust_settings
# 调整OpenWrt文件的相关设置，删除不需要的文件和服务
adjust_settings() {
    cd "${current_path}"
    echo -e "${STEPS} 开始调整OpenWrt文件的设置..."

    echo -e "${INFO} 解压Openwrt。"
    rm -rf "${tmp_path}" && mkdir -p "${tmp_path}"
    tar -xzf "${openwrt_path}/${openwrt_file_name}" -C "${tmp_path}"

    # ... (其他文件设置的优化)

    echo -e "${INFO} 调整banner设置。"
    echo " Board: docker | Production Date: $(date +%Y-%m-%d)" >>"${tmp_path}/etc/banner"
    echo "───────────────────────────────────────────────────────────────────────" >>"${tmp_path}/etc/banner"
}

# 函数：make_dockerimg
# 制作Docker镜像并将其移动到输出目录
make_dockerimg() {
    cd "${tmp_path}"
    echo -e "${STEPS} 开始制作Docker镜像..."

    tar -czf "${docker_rootfs_file}" *
    [[ "${?}" -eq "0" ]] || error_msg "Docker镜像创建失败。"

    rm -rf "${out_path}" && mkdir -p "${out_path}"
    mv -f "${docker_rootfs_file}" "${out_path}"
    [[ "${?}" -eq "0" ]] || error_msg "移动Docker镜像失败。"
    echo -e "${INFO} Docker镜像打包成功。"

    cd "${current_path}"

    # ... (其他处理，比如添加Dockerfile等)

    rm -rf "${tmp_path}"
    sync && sleep 3
    echo -e "${INFO} Docker文件列表： \n$(ls -l ${out_path})"
    echo -e "${SUCCESS} Docker镜像创建成功。"
}

# 设置默认参数
current_path="${PWD}"
openwrt_path="${current_path}/openwrt"
openwrt_rootfs_file="*rootfs.tar.gz"
docker_rootfs_file="openwrt-docker-armvirt-64-default-rootfs.tar.gz"
docker_path="${current_path}/config/docker"
make_path="${current_path}/make-openwrt"
common_files="${make_path}/openwrt-files/common-files"
tmp_path="${current_path}/tmp"
out_path="${current_path}/out"

# 设置彩色输出参数
STEPS="[\033[95m 步骤 \033[0m]"
INFO="[\033[94m 信息 \033[0m]"
SUCCESS="[\033[92m 成功 \033[0m]"
WARNING="[\033[93m 警告 \033[0m]"
ERROR="[\033[91m 错误 \033[0m]"
#
#================================================================================================

# 显示欢迎消息
echo -e "${STEPS} 欢迎使用Docker镜像制作工具。"
echo -e "${INFO} 制作路径：[ ${PWD} ]"

# 调用函数执行任务
check_depends
find_openwrt
adjust_settings
make_dockerimg

# 所有过程完成
wait
