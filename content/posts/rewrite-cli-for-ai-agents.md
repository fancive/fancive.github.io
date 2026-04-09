---
title: "你的 CLI 该为 AI Agent 重写了"
date: 2026-04-09T12:00:00+08:00
description: "给人用的命令行和给 Agent 用的命令行，是两种东西。七个设计原则，用真实内部工具和知名开源 CLI 逐条拆解。"
tags: ["AI Agent", "CLI", "Developer Experience", "工具设计", "Claude Code"]
categories:
  - 软件架构
cover:
  image: "/images/covers/cli-agent-dx.svg"
  alt: "Human DX vs Agent DX"
draft: false
---

给人用的命令行和给 Agent 用的命令行，是两种东西。别慌——你不需要推翻重来，只需要加一张新脸。

<!--more-->

## 一个真实的尴尬场景

我有一个内部部署工具 `idp-cli`，专门给脚本和 AI Agent 调用（区别于交互式的 `idp`）。用法很直接：

```bash
idp-cli deploy --app gms --branch master --platform all --isp all
```

看起来很"自动化友好"了对吧？JSON 输出、非交互、四个 flag 一传就走。

但当我让 Claude Code 调用它时，事情开始变味：

- Agent 第一次调了 `idp-cli deploy --app gms --branch main`——少了两个必填 flag，直接报错
- 第二次它"学聪明了"，加上了 `--platform production`——但枚举值只有 `test/sandbox/online`，又错了
- 第三次终于对了，但 **直接部署到了生产环境，没有任何确认机制**

这个工具为"脚本"设计，不是为"会犯错的智能体"设计。

2026 年 3 月，Google 的 Justin Poehnelt 写了一篇文章，标题是 *"You Need to Rewrite Your CLI for AI Agents"*。核心观点只有一句：

> **Human DX 优化的是"好找、容错"。Agent DX 优化的是"可预测、防得住"。**

这不是一个理论问题。2026 年初，Claude Code 和 Codex CLI 让"Agent 直接调用命令行工具"从实验变成了日常。当你团队里一半的 CLI 调用来自 Agent 而不是人，CLI 的设计假设就需要重新审视了。

读完之后，我回头看自己写的一堆 CLI，发现每一个都中枪了。

为什么不直接用 MCP / function calling，还走 CLI？因为 CLI 是存量最大的工具接口——绝大多数内部工具不会有 MCP server，JSON 入口是成本最低的"Agent 可调用化"方案。

---

## 七个设计原则，逐条拆解

### 1. 一个 JSON 入口 > 一堆 Flag

**人习惯**一次记一个 flag，`--name`、`--email`、`--role` 分开传。
**Agent 习惯**直接把 API schema 映射成一个 JSON payload。

对比我的 `idp-cli`：

```bash
# 现状：Agent 要猜四个 flag 的名字和枚举值
idp-cli deploy --app gms --branch master --platform all --isp all

# Agent 友好版：直接传 JSON，映射 API schema
idp-cli deploy --json '{"app":"gms","branch":"master","platform":"all","isp":"all"}'
```

这不是"多此一举"。当 flag 有 10 个、其中 3 个有枚举约束、2 个互斥时，Agent 拼 flag 的出错率远高于拼一个 JSON。更关键的是，JSON payload 可以直接用 schema 验证——一行 `jsonschema.validate()` 搞定类型、枚举、必填的全量校验，而 flag 组合约束需要手写验证逻辑。这才是 JSON 入口的核心优势：**可机器验证性**。

**知名案例：Stripe CLI**

Stripe 的设计哲学是"CLI 就是 API 的薄壳"——每个子命令直接映射一个 API endpoint，参数结构和 API 文档完全一致。Agent 不需要学一套"CLI 方言"，直接按 API 文档传参就行。

---

### 2. Schema 自省 > `--help` 文本

**人**读 `--help` 觉得很自然。
**Agent** 读 `--help` 是在用 token 解析非结构化文本。

我的 `pis` 工具（服务实例查询）的帮助输出长这样：

```
Usage:
  pis query [service] [flags]

Flags:
  -s, --service string   Service key
  -g, --group string     Group name
      --pick string      Pick strategy: auto|random|primary-first
      --json             Output JSON
      --pretty           Pretty-print JSON
```

Agent 要从这段文本里提取出"pick 参数的可选值是 auto、random、primary-first"，需要正则匹配或语义理解。浪费。

如果改成：

```bash
pis schema query
```
```json
{
  "required": ["service"],
  "properties": {
    "service": {"type": "string", "description": "BNS service key"},
    "group": {"type": "string"},
    "pick": {"type": "string", "enum": ["auto","random","primary-first","primary-last","index"]}
  }
}
```

Agent 拿到 JSON schema，**零歧义、零 token 浪费**。

**知名案例：kubectl explain**

```bash
kubectl explain pod.spec.containers.resources
```

直接从 API Server 的 OpenAPI schema 拉取字段定义，包括类型、描述、是否必填。这是"活的文档"——永远和当前集群版本一致，不存在文档过期的问题。

Google 的 `gws`（Workspace CLI）更进一步：启动时从 Google API Discovery Service 动态构建命令树，命令和参数永远和线上 API 一致。

---

### 3. Skill File > Help Text

**人**通过 `--help` 和文档学习工具。
**Agent** 通过注入的上下文学习工具。

`--help` 能告诉 Agent `--env` 接受 string，但不能告诉它只有两个合法值 `online` 和 `shahe`。这个 gap 就是 Skill File 要填的。

我给 Claude Code 写了一系列 skill 文件（Markdown 格式），教它怎么用我的工具：

```markdown
# ES Log Query Skill

## 用法
query.py <service> <env> <keyword> [--hours N] [--size N] [--json]

## 不变量
- 默认查最近 1 小时，生产问题排查建议 --hours 4
- --size 超过 50 会导致 context 过大，建议 20
- 环境只有 online 和 shahe，没有 dev
```

关键是最后那段**不变量**——这不是帮助文档，而是 Agent 必须遵守的规则。"环境只有 online 和 shahe"这句话，阻止了 Agent hallucinate 出 `--env production` 或 `--env staging`。

Poehnelt 在文章中建议 CLI 直接附带 `SKILL.md` 文件，编码 agent 级别的约束（如"所有 mutation 操作必须先 `--dry-run`"）。不管你用什么 Agent 框架，附带一个机器可读的约束文件都是好实践。如果你在用 Claude Code，你的 `.claude/skills/` 目录就是 Skill File。

---

### 4. 保护 Context Window：字段掩码 + 分页

Agent 的上下文窗口是有限资源。主流 LLM 的上下文窗口约 128k-200k token；200 个实例的完整 JSON 可能占 8-15k token，相当于把 Agent 的"工作记忆"吃掉 5-10%——留给推理和规划的空间就少了。

我的 `pis query --json` 会返回每个实例的全部字段：

```json
{
  "instances": [
    {"ip":"10.1.2.3","port":8080,"tag":"primary","status":"running","hostname":"host-001","idc":"gz","rack":"A3"},
    "... x200"
  ]
}
```

Agent 可能只需要 IP 和状态。但它没法说"只给我这两个字段"。

**应该怎么做：**

```bash
# 字段掩码：只返回 agent 需要的字段
pis query myservice --json --fields ip,status

# NDJSON 分页：流式输出，agent 可以随时停
pis query myservice --json --ndjson
```

**知名案例对比：**

| CLI | 字段过滤方式 |
|-----|-------------|
| `gh pr list --json number,title` | `--json` 直接指定字段 |
| `kubectl get pods -o jsonpath='{.items[*].metadata.name}'` | JSONPath 表达式 |
| `gcloud compute instances list --format='json(name,status)'` | `--format` 内嵌字段列表 |
| `docker ps --format '{{.Names}} {{.Status}}'` | Go 模板 |
| `rg --json pattern` | NDJSON 流式输出，每条匹配一个 JSON 对象 |

ripgrep 的 NDJSON 模式尤其值得学习：每条匹配是独立的 JSON 对象（包含文件名、行号、匹配内容），Agent 可以逐条处理，不用等全部结果返回。Eclipse Theia IDE 就是从解析 rg 的人类输出切换到消费 `rg --json` 的。

---

### 5. 输入强化：防的不是 Typo，是 Hallucination

人打错命令是少敲一个字母。Agent 打错命令是**凭空编造**一个看起来合理但不存在的参数。

最常见的 hallucination 模式其实很日常：Agent 在别的项目里见过 `production-bucket` 这个名字，就"自信地"把它迁移到你的 `bos_cli.py` 里——但你的 bucket 叫 `imeres`。它不是恶意的，是**把别处的经验当成了这里的事实**。类似的：

- 把枚举值 `online` 写成 `production`（在另一个项目里见过）
- 字段名 `--app` 写成 `--name`（和其他 CLI 混了）
- 多传一个工具不支持的 flag（从 `--help` 文本"推理"出来的）

更极端的情况还有路径遍历（`../../etc/passwd`）、控制字符注入、双重编码（`%252F`）等。

这不是传统的安全加固（防恶意用户），而是**防好心但不靠谱的队友**。

防御思路很直接——对所有 Agent 可调用的参数做 allowlist 校验：

```python
VALID_ENVS = {"online", "shahe"}
VALID_BUCKETS = {"imeres", "imepri", "imepub"}

def validate_agent_input(env, bucket):
    if env not in VALID_ENVS:
        return {"error": f"invalid env '{env}', must be one of {VALID_ENVS}"}
    if bucket not in VALID_BUCKETS:
        return {"error": f"invalid bucket '{bucket}', must be one of {VALID_BUCKETS}"}
    if ".." in bucket or "\x00" in bucket:
        return {"error": "suspicious input detected"}
```

枚举值用 allowlist，路径参数做规范化检查。简单但有效。

---

### 6. `--dry-run`：Agent 的确认按钮

人类可以看到交互式确认弹窗，犹豫一下再按回车。Agent 没有"犹豫"这个动作。

这是我工具中**最大的安全缺口**。`idp`（交互版）有确认提示：

```
即将部署 gms 到 all 平台，确认？[Y/n]
```

但 `idp-cli`（Agent 版）直接执行，没有任何安全缓冲。一次 hallucination 就是一次生产事故。

**应该怎么做：**

```bash
idp-cli deploy --json '{"app":"gms","branch":"master","platform":"all"}' --dry-run
```
```json
{
  "would_deploy": true,
  "app": "gms",
  "branch": "master",
  "affected_instances": 42,
  "estimated_duration": "8m",
  "risk_level": "high",
  "reason": "deploying to all platforms"
}
```

Agent 先看到"会影响 42 个实例、风险高"，再决定是否真的执行。

**知名案例：kubectl 的两级 dry-run**

```bash
# 客户端验证：只检查 YAML 格式，不联系 API Server
kubectl apply -f deploy.yaml --dry-run=client -o json

# 服务端验证：发送到 API Server 做完整校验（admission controller、quota），但不持久化
kubectl apply -f deploy.yaml --dry-run=server -o json
```

Terraform 更彻底——`plan` 和 `apply` 是两个独立命令，中间有一个人类必须审查的 diff。这个模式天然适合 Agent：先 `terraform plan -out=tfplan`，再 `terraform show -json tfplan` 让 Agent 审查变更，最后才 `terraform apply tfplan`。

---

### 7. 同一个工具，人 / Agent / CI 三张脸

同一个能力，不同消费者需要不同的接口：

| 消费者 | 接口 | 特点 |
|--------|------|------|
| 人类 | 交互式 CLI | 彩色输出、确认提示、自动补全 |
| Agent | 结构化 CLI 或 MCP | JSON I/O、dry-run、schema 自省 |
| CI/CD | 环境变量 + 静默模式 | headless auth、`--quiet`、退出码 |

我现在的做法是**两个独立二进制**：`idp`（人类版）和 `idp-cli`（Agent 版）。这能用，但维护成本翻倍。

更好的做法是 **一个二进制，根据上下文自动切换**。GitHub CLI 已经这么做了：

```bash
# 人类模式：彩色表格、截断长字段
gh pr list

# 管道模式（检测到 stdout 不是 TTY）：自动切换为 tab 分隔、无颜色、不截断
gh pr list | head -5

# Agent 模式：JSON + 字段选择 + jq 过滤
gh pr list --json number,title --jq '.[].title'
```

一个二进制、零配置、根据调用上下文自动选择输出格式。优雅。

Terraform 用环境变量实现类似效果：`TF_IN_AUTOMATION=1` 会抑制所有"人类引导文本"（比如 "Run terraform apply to..."），让输出对程序友好。

---

## 速查表：Human DX vs Agent DX

| 原则 | Human DX（传统） | Agent DX（新要求） |
|------|-----------------|-------------------|
| 输入格式 | 多个便捷 flag | 一个 `--json` payload，可 schema 验证 |
| 文档方式 | `--help` 文本 | 运行时 Schema 自省 + Skill File |
| 学习路径 | 读文档、试错 | 注入上下文不变量 |
| 输出控制 | 默认人类可读 | JSON + 字段掩码 + NDJSON 分页 |
| 输入验证 | 防 typo | 防 hallucination（allowlist + 路径规范化） |
| 安全机制 | 确认提示 | `--dry-run` 返回 plan |
| 部署模式 | 一个二进制给人用 | 一个二进制，三张脸（人/Agent/CI） |

---

## 常见误区

在动手改造之前，先避开几个坑：

- **"加了 `--json` 就算 Agent 友好了"**——输出 JSON 只是第一步。输入验证、dry-run、schema 自省都没做，Agent 照样会出事。
- **"Agent 会自己学会用工具"**——不会。它会"自信地"用错。没有 Skill File 或 Schema 约束，Agent 就是在盲猜。
- **"安全问题是安全团队的事"**——Agent hallucination 不是安全攻击，是日常使用中的常态。每个 CLI 作者都需要考虑。

---

## 改造路径：从哪里开始？

不需要一次全改。Poehnelt 建议的渐进路径：

```
第一步：加 --output json（几乎零成本）
  ↓
第二步：严格验证输入（防 hallucination）
  ↓
第三步：暴露 schema 自省接口
  ↓
第四步：实现字段掩码（--fields）
  ↓
第五步：加 --dry-run
  ↓
第六步：附带 Skill File + MCP 接口
```

对我自己来说，优先级很明确：**先给 `idp-cli` 加 `--dry-run`**。这是唯一有真实破坏力的 Agent 可调用工具，且改动量小——验证逻辑已经有了，只需要在最后一步前加一个"返回 plan 而非执行"的分支。预计半天工作量，改完之后 Claude Code 调用部署就从"盲射"变成"瞄准再打"。

---

## 总结

CLI 设计正在经历一次范式转移。过去 40 年，我们围绕"人类在终端里打字"优化：彩色输出、交互补全、模糊匹配、友好的错误提示。这些对 AI Agent 全都没用，甚至有害。

Agent 不需要你的输出好看，它需要你的输出**可解析**。
Agent 不需要你的错误提示友好，它需要你的输入验证**严格**。
Agent 不需要你的帮助文档详尽，它需要你的 schema **可查询**。
Agent 不需要你的确认弹窗，它需要你的 `--dry-run` **真的能用**。

好消息是，这些改造大多是增量的——加一个 `--json` flag 不会破坏现有用户体验。你不需要重写 CLI，你需要给它**加一张新脸**。

---

*参考：*
- *Justin Poehnelt, ["You Need to Rewrite Your CLI for AI Agents"](https://justin.poehnelt.com/posts/rewrite-your-cli-for-ai-agents/), 2026-03*
