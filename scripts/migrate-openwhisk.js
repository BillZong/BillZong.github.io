'use strict';

// 给 8 篇 OpenWhisk 老文章追加"已纳入新系列"声明段。
//
// 触发条件：文章 front-matter 同时满足
//   - categories 包含 'Serverless'
//   - tags 包含 'OpenWhisk'
//   - 没有 series 字段（避开新系列文章）
//   - 标题在 MIGRATION_MAP 映射表里
//
// 追加段直接走 markdown，让 fluid 主题渲染。
// 老文章正文不动，permalink 保持原样。

// 老文章标题 → 系列内序号 + 新章节标题
const MIGRATION_MAP = {
  '搭建OpenWhisk': {
    order: 1,
    newTitle: 'OpenWhisk 入门与生态总览',
  },
  'Ansible在Mac本地部署OpenWhisk填坑记': {
    order: 2,
    newTitle: 'Mac 本地部署实战',
  },
  'Helm部署OpenWhisk全流程分析': {
    order: 3,
    newTitle: 'Helm 部署全流程解析',
  },
  'OpenWhisk部署配置说明': {
    order: 4,
    newTitle: '部署配置详解',
  },
  '如何缩短K8S部署固定版本OpenWhisk集群的时长': {
    order: 5,
    newTitle: 'K8s 部署加速：从小时级到分钟级',
  },
  'OpenWhisk开发环境配置说明': {
    order: 6,
    newTitle: '开发环境配置',
  },
  'OpenWhisk当前监控指标详细说明': {
    order: 7,
    newTitle: '监控指标体系',
  },
  '阿里云腾讯云OpenWhisk性能测试方案': {
    order: 8,
    newTitle: '性能基准：阿里云 vs 腾讯云',
  },
};

const SERIES_NAME = 'OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本';
const SERIES_INDEX_URL = '/openwhisk-retro/';
const SENTINEL = '<!-- series-migration-sentinel -->'; // 防止重复追加

function queryToArray(q) {
  if (!q) return [];
  if (Array.isArray(q)) return q;
  // hexo warehouse _Query: has toArray() / length / map() / forEach()
  if (typeof q.toArray === 'function') return q.toArray();
  if (typeof q.length === 'number') {
    const arr = [];
    for (let i = 0; i < q.length; i++) arr.push(q[i]);
    return arr;
  }
  return [];
}

function getNames(q) {
  return queryToArray(q).map((x) => (x && x.name) ? x.name : x).filter(Boolean);
}

function isTarget(data) {
  if (data.series) return false; // 跳过新系列文章
  if (data.layout && data.layout !== 'post') return false;

  const catNames = getNames(data.categories);
  const tagNames = getNames(data.tags);

  const inServerless = catNames.includes('Serverless');
  const hasOpenWhisk = tagNames.some((t) => t.toLowerCase() === 'openwhisk');
  return inServerless && hasOpenWhisk && MIGRATION_MAP[data.title] != null;
}

function buildMigrationNote(data, info) {
  return `

${SENTINEL}
> 📚 **本文已纳入新系列**：[《${SERIES_NAME}》](${SERIES_INDEX_URL})（系列第 **${info.order}** 节 / 共 8 节 · **${info.newTitle}**）。新文章中保留对本文的引用，老 permalink 仍可访问。
`;
}

hexo.extend.filter.register('before_post_render', function (data) {
  if (!isTarget(data)) return data;

  // 防止重复追加
  if (data.content && data.content.includes(SENTINEL)) return data;

  const info = MIGRATION_MAP[data.title];
  data.content = (data.content || '').replace(/\s*$/, '') + buildMigrationNote(data, info);
  return data;
});
