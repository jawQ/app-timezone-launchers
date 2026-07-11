# 地区参考

[English](regional-references.md)

本文列出不同地区具有代表性的办公和聊天工具。示例仅用于选择时区时参考，并非严格排名。

> 仅支持 macOS：本仓库面向 macOS `.app` 启动命令设计。尚未测试 Windows 和 Linux，因而不提供支持。

## 参考表

| 地区 | 时区 | 常见办公工具 | 常见聊天工具 |
| --- | --- | --- | --- |
| 美国旧金山 | `America/Los_Angeles` | Microsoft Teams、Slack、Zoom | Messenger、iMessage、WhatsApp |
| 欧洲德国 | `Europe/Berlin` | Microsoft Teams、Slack、Zoom | WhatsApp、Telegram、Signal |
| 日本 | `Asia/Tokyo` | Microsoft Teams、LINE WORKS、Chatwork | LINE、WhatsApp、Messenger |
| 韩国 | `Asia/Seoul` | Microsoft Teams、Slack、KakaoWork | KakaoTalk、Telegram、WhatsApp |
| 新加坡 | `Asia/Singapore` | Microsoft Teams、Slack、Zoom | WhatsApp、Telegram、Messenger |

## 飞书/Lark 示例

```bash
# 美国旧金山
LARK_TZ=America/Los_Angeles feishu-tz

# 欧洲德国
LARK_TZ=Europe/Berlin feishu-tz

# 日本
LARK_TZ=Asia/Tokyo feishu-tz

# 韩国
LARK_TZ=Asia/Seoul feishu-tz

# 新加坡
LARK_TZ=Asia/Singapore feishu-tz
```

## 微信示例

```bash
# 美国旧金山
WECHAT_TZ=America/Los_Angeles wechat-tz

# 欧洲德国
WECHAT_TZ=Europe/Berlin wechat-tz

# 日本
WECHAT_TZ=Asia/Tokyo wechat-tz

# 韩国
WECHAT_TZ=Asia/Seoul wechat-tz

# 新加坡
WECHAT_TZ=Asia/Singapore wechat-tz
```

## Slack 示例

```bash
# 美国旧金山
SLACK_TZ=America/Los_Angeles slack-tz

# 欧洲德国
SLACK_TZ=Europe/Berlin slack-tz

# 日本
SLACK_TZ=Asia/Tokyo slack-tz

# 韩国
SLACK_TZ=Asia/Seoul slack-tz

# 新加坡
SLACK_TZ=Asia/Singapore slack-tz
```

## LINE 示例

```bash
# 美国旧金山
LINE_TZ=America/Los_Angeles line-tz

# 欧洲德国
LINE_TZ=Europe/Berlin line-tz

# 日本
LINE_TZ=Asia/Tokyo line-tz

# 韩国
LINE_TZ=Asia/Seoul line-tz

# 新加坡
LINE_TZ=Asia/Singapore line-tz
```

## 另见

- [可选启动命令](optional-launchers.zh-CN.md)
- [ZoneLaunch App](../app/overview.zh-CN.md)
