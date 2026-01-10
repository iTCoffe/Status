// 模拟每个服务的健康数据
const SERVICES_DATA = [
  {
    name: "主站服务 (Main Website)",
    url: "https://example.com",
    // 模拟最近30天的状态：0: 正常, 1: 部分故障, 2: 严重故障, 3: 无数据
    history: [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0]
  },
  {
    name: "API 接口 (Public API)",
    url: "https://api.example.com",
    history: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  }
];

const STATUS_MAP = {
  0: { text: 'Operational', class: 'success', desc: '系统运行正常' },
  1: { text: 'Degraded', class: 'partial', desc: '部分服务响应缓慢' },
  2: { text: 'Down', class: 'failure', desc: '服务当前不可用' },
  3: { text: 'No Data', class: 'nodata', desc: '无监控数据' }
};

function genAllReports() {
  const reportsContainer = document.getElementById('reports');
  const template = document.getElementById('statusContainerTemplate');
  const squareTemplate = document.getElementById('statusSquareTemplate');

  SERVICES_DATA.forEach(service => {
    // 1. 克隆外层容器
    const card = template.cloneNode(true);
    card.id = "";
    
    // 计算当前状态（以最后一天为准）
    const currentStatus = STATUS_MAP[service.history[service.history.length - 1]];
    
    // 2. 替换头部信息
    let html = card.innerHTML
      .replace('$title', service.name)
      .replace(/\$url/g, service.url)
      .replace('$status', currentStatus.text)
      .replace('$color', currentStatus.class)
      .replace('$upTime', '99.9%'); // 实际开发可根据 history 计算百分比
    
    card.innerHTML = html;

    // 3. 生成 30 天的方块流
    const streamContainer = document.createElement('div');
    streamContainer.className = 'statusStreamContainer';

    service.history.forEach((statusStep, index) => {
      const square = squareTemplate.cloneNode(true);
      const statusInfo = STATUS_MAP[statusStep];
      
      square.id = "";
      square.className = `statusSquare ${statusInfo.class}`;
      
      // 绑定鼠标交互显示 Tooltip
      square.onmouseenter = (e) => showTooltip(e, index, statusInfo);
      square.onmouseleave = hideTooltip;
      
      streamContainer.appendChild(square);
    });

    card.appendChild(streamContainer);
    reportsContainer.appendChild(card);
  });
}

function showTooltip(e, dayOffset, info) {
  const tooltip = document.getElementById('tooltip');
  const date = new Date();
  date.setDate(date.getDate() - (29 - dayOffset));

  document.getElementById('tooltipDateTime').innerText = date.toLocaleDateString();
  document.getElementById('tooltipStatus').innerText = info.text;
  document.getElementById('tooltipStatus').className = info.class;
  document.getElementById('tooltipDescription').innerText = info.desc;

  tooltip.style.opacity = "1";
  tooltip.style.top = `${e.pageY - 120}px`;
  tooltip.style.left = `${e.pageX - 120}px`;
}

function hideTooltip() {
  document.getElementById('tooltip').style.opacity = "0";
}
