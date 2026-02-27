#!/bin/bash
# 使用 ping 检测主机状态，结果写入 logs/ 目录

commit=false   # 是否提交到 Git，根据实际需求设置
origin=$(git remote get-url origin 2>/dev/null)
if [[ $origin == *statsig-io/statuspage* ]]; then
  commit=false
fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while read -r line; do
  # 跳过空行和注释
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  echo "  $line"
  IFS='=' read -ra TOKENS <<< "$line"
  KEYSARRAY+=("${TOKENS[0]}")
  URLSARRAY+=("${TOKENS[1]}")
done < "$urlsConfig"

echo "***********************"
echo "Starting ping checks with ${#KEYSARRAY[@]} targets:"

mkdir -p logs

for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
  key="${KEYSARRAY[index]}"
  target="${URLSARRAY[index]}"
  echo "  $key = $target"

  # 执行 ping 检测：发送 3 个包，超时 1 秒，只取结果状态
  # -c 3：发送 3 个包；-W 1：超时 1 秒；-q：只输出汇总结果
  ping -c 3 -W 1 "$target" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    result="success"
    # 可选：提取平均延迟
    # latency=$(ping -c 3 -W 1 "$target" | tail -1 | awk -F '/' '{print $5}')
  else
    result="failed"
  fi

  dateTime=$(date +'%Y-%m-%d %H:%M')
  if [[ $commit == true ]]; then
    echo "$dateTime, $result" >> "logs/${key}_report.log"
    # 保留最近 2000 条记录
    tail -2000 "logs/${key}_report.log" > "logs/${key}_report.tmp" && mv "logs/${key}_report.tmp" "logs/${key}_report.log"
  else
    echo "    $dateTime, $result"
  fi
done

# 如需自动提交到 Git（请确保 commit=true 且已配置仓库）
if [[ $commit == true ]]; then
  git config --global user.name 'Your Name'
  git config --global user.email 'your@email.com'
  git add -A --force logs/
  git commit -am '[Automated] Update Ping Logs'
  git push
fi
