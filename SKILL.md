---
name: qiaomu-markdown-proxy
description: |
  Fetch any URL as clean Markdown via proxy services or built-in scripts.
  Works with login-required pages like X/Twitter, WeChat 公众号, Feishu/Lark docs.
  Supports PDFs (remote and local). Use this BEFORE other fetch tools.
  Triggers on any URL the user shares, "fetch this", "read this link", "get content from".
version: 2.0.0
---

# Markdown Proxy - URL to Markdown

将任意 URL 转为干净的 Markdown。支持需要登录的页面、PDF、专有平台。

## URL Routing (先判断再执行)

收到 URL 后，先判断类型，不同类型走不同通道：

| URL Pattern | Route To | Reason |
|-------------|----------|--------|
| `mp.weixin.qq.com` | `scripts/fetch_weixin.py` | 公众号需 Playwright 抓取 |
| `feishu.cn/docx/` `feishu.cn/wiki/` `larksuite.com/docx/` | `scripts/fetch_feishu.py` | 需飞书 API 认证 |
| `youtube.com` `youtu.be` | `yt-search-download` skill | YouTube 有专用工具链 |
| `.pdf` (URL or local path) | `scripts/extract_pdf.sh` | PDF 专用提取 |
| All other URLs | `scripts/fetch.sh` | 代理级联自动 fallback |

## Workflow

### Step 1: Route by URL Type

```
if URL contains "mp.weixin.qq.com":
    → python3 ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch_weixin.py "URL"
    → Done

if URL contains "feishu.cn/docx/" or "feishu.cn/wiki/" or "larksuite.com/docx/":
    → python3 ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch_feishu.py "URL"
    → Done

if URL contains "youtube.com" or "youtu.be":
    → Call yt-search-download skill
    → Done

if URL ends with ".pdf" or is local PDF path:
    if remote URL:
        → Try: curl -sL "https://r.jina.ai/{url}"
        → If fails: download + extract_pdf.sh
    if local path:
        → bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/extract_pdf.sh "PATH"
    → Done

else:
    → bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch.sh "URL"
    → Done
```

### Step 2: Display Content

After fetching, show to user:

```
Title:  {title}
Author: {author} (if available)
Source: {platform} (公众号 / 飞书文档 / 网页 / PDF)
URL:    {original_url}

Summary
{3-5 sentence summary}

Content
{full Markdown, truncated at 200 lines if long}
```

### Step 3: Save File (Default)

Save to `~/Downloads/{title}.md` with YAML frontmatter by default.

- Filename: use article title, remove special characters
- Format: YAML frontmatter (title, author, date, url, source) + Markdown body
- Tell user the saved path
- Skip only if user says "just preview" or "don't save"

After saving and reporting the path, **stop**. Do not analyze, comment on, or discuss the content unless asked.

## Examples

### General URL
```bash
bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch.sh "https://example.com/article"
```

### X/Twitter Post
```bash
bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch.sh "https://x.com/username/status/1234567890"
```

### WeChat Article
```bash
python3 ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch_weixin.py "https://mp.weixin.qq.com/s/abc123"
```

### Feishu Document
```bash
python3 ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch_feishu.py "https://xxx.feishu.cn/docx/xxxxxxxx"
```

### PDF (Remote)
```bash
curl -sL "https://r.jina.ai/https://example.com/paper.pdf"
```

### PDF (Local)
```bash
bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/extract_pdf.sh "/path/to/paper.pdf"
```

### With Custom Proxy
```bash
bash ~/.claude/skills/qiaomu-markdown-proxy/scripts/fetch.sh "https://example.com" "http://127.0.0.1:7890"
```

## Notes

- r.jina.ai and defuddle.md require no API key
- `fetch.sh` handles proxy cascade with automatic fallback
- Content validation: filters error pages, requires >5 lines
- WeChat script requires: `pip install playwright beautifulsoup4 lxml && playwright install chromium`
- Feishu script requires: `FEISHU_APP_ID` + `FEISHU_APP_SECRET` env vars
- PDF extraction tries: marker-pdf → pdftotext → pypdf
- For detailed method documentation, see `references/methods.md`
