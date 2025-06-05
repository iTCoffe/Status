#!/bin/bash

# 改进版健康检查脚本
# 版本: 1.1
# 修改说明: 
#   1. 保留原始urls.cfg配置方式
#   2. 优化状态检测逻辑
#   3. 生成统一的status.json
#   4. 添加自动提交功能开关

# === 配置区域 ===
STATUS_FILE="status.json"        # 输出状态文件
CONFIG_FILE="urls.cfg"           # 服务配置文件
LOG_FILE="health-check.log"       # 详细日志
DATE_FORMAT="+%Y-%m-%dT%H:%M:%S%z"  # 日期时间格式

# === 脚本行为控制 ===
commit=true  # 默认启用自动提交
origin=$(git remote get-url origin)

# 如果在原始仓库中运行，则禁用提交
if [[ $origin == *statsig-io/statuspage* ]]; then
  commit=false
fi

# === 辅助函数 ===

# 记录日志
log() {
    local message="$1"
    local timestamp
    timestamp=$(date "$DATE_FORMAT")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# 检查服务状态
check_service() {
    local service_name=$1
    local service_url=$2
    
    local status="unknown"
    local http_status=""
    local response_time=""
    
    # 尝试4次获取有效状态
    for i in {1..4}; do
        # 使用curl获取详细响应信息
        local start_time
        start_time=$(date +%s%3N)  # 毫秒级时间戳
        
        local result
        result=$(curl -L -I -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$service_url")
        
        local end_time
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))
        
        # 记录每次尝试结果
        log "尝试 $i/$service_name ($service_url): HTTP状态 $result 响应时间 ${response_time}ms"
        
        # 验证状态码
        if [[ "$result" =~ ^[0-9]+$ ]]; then
            http_status=$result
            # 成功状态码
            if [ "$result" -eq 200 ] || [ "$result" -eq 202 ] || [ "$result" -eq 301 ] || [ "$result" -eq 302 ] || [ "$result" -eq 307 ]; then
                status="success"
                break
            # 客户端错误
            elif [ "$result" -ge 400 ] && [ "$result" -lt 500 ]; then
                status="warning"
            # 服务器错误
            elif [ "$result" -ge 500 ]; then
                status="error"
            # 其他状态码
            else
                status="unknown"
            fi
        else
            http_status="000"
            status="down"
        fi
        
        # 如果不是最后一次尝试，等待5秒
        if [ "$i" -lt 4 ]; then
            sleep 5
        fi
    done

    # 返回JSON格式的状态报告
    cat <<EOF
    {
        "name": "$service_name",
        "url": "$service_url",
        "status": "$status",
        "httpStatus": "$http_status",
        "responseTime": $response_time,
        "lastChecked": "$(date "$DATE_FORMAT")"
    }
EOF
}

# === 主脚本 ===

# 1. 初始化日志文件
echo "=== 开始服务健康检查 ===" > "$LOG_FILE"
log "配置文件: $CONFIG_FILE"
log "目标状态文件: $STATUS_FILE"
log "提交功能: $commit"

# 2. 读取服务配置文件
KEYSARRAY=()
URLSARRAY=()
log "读取 $CONFIG_FILE"
while IFS='=' read -r key value; do
    # 跳过注释行和空行
    [[ $key =~ ^#.* || -z $key ]] && continue
    
    log "添加服务: $key = $value"
    KEYSARRAY+=("$key")
    URLSARRAY+=("$value")
done < "$CONFIG_FILE"

log "发现服务数量: ${#KEYSARRAY[@]}"

# 3. 创建临时状态JSON
temp_file=$(mktemp)
echo "[" > "$temp_file"

# 4. 逐个检查服务并记录状态
first=true
for (( index=0; index < ${#KEYSARRAY[@]}; index++)); do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$temp_file"
    fi
    
    log "正在检查服务: $key ($url)"
    check_service "$key" "$url" >> "$temp_file"
done

echo "" >> "$temp_file"
echo "]" >> "$temp_file"

# 5. 添加整体状态信息
{
    echo '{"metadata": {'
    echo '"generatedAt": "'$(date "$DATE_FORMAT")'",'
    echo '"totalServices": '${#KEYSARRAY[@]}','
    echo '"commitEnabled": '$commit','
    echo '"configFile": "'$CONFIG_FILE'",'
    echo '"version": "1.1"'
    echo '},'
    echo '"services":'
    cat "$temp_file"
} > "$STATUS_FILE"

rm "$temp_file"

# 6. 记录报告
log "状态文件已生成: $STATUS_FILE"
log "==="

# 7. 自动提交处理
if [[ $commit == true ]]; then
    log "执行自动提交..."
    git config --global user.name '健康检查机器人'
    git config --global user.email 'healthcheck@example.com'
    git add "$STATUS_FILE" "$LOG_FILE"
    git commit -m "[自动更新] 服务健康检查报告 $(date +'%Y-%m-%d %H:%M')"
    git push
    log "提交完成"
fi

echo "健康检查完成 - 查看 $STATUS_FILE 获取完整报告"
exit 0
