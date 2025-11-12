# 鹿之鸣（luzhiming） · MacOS 菜单栏语音转文字助手

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-darkred.svg)](./LICENSE)
[![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange)](https://www.swift.org/)
[![Platform macOS 10.14+](https://img.shields.io/badge/Platform-macOS%2010.14%2B-lightgrey)](https://www.apple.com/macos/)

<img width="128" height="128" alt="icon_512x512" src="https://github.com/user-attachments/assets/f6950aee-6ae3-4c57-bf03-2cf5b176c7d5" />


一个轻量、开箱即用的 macOS 菜单栏应用：一键录音、自动转字幕、结果入剪贴板。支持多家 ASR 服务商，可自由切换。

> 适合会议纪要、临时灵感记录、视频字幕粗转等高频场景。
>
> **许可证**：AGPL-3.0（禁止商业二次开发）

---

## 功能特性

- 漂浮圆形录音控件（80×80），可拖拽、始终置顶、点击即录/停
- 系统菜单栏入口，内置设置面板（NSPopover）
- 语音转文字：
  - OpenAI Whisper / GPT-4o Transcribe（已接入）
  - 智谱 GLM-ASR（已接入）
  - 抖音豆包 Doubao（计划中）
- 结果自动复制到剪贴板
- 录音时长控制：最短/最长时长可配，边录边显示进度（0.1s 精度）
- 文件缓存管理：限制历史录音数量、超过上限自动清理
- 本地配置与密钥文件存储，独立于系统偏好/钥匙串


## 预览与交互

- 圆形悬浮按钮：
  - 单击：开始/结束录音
  - 拖拽：移动位置，保持在最上层
- 菜单栏图标：
  - 打开「设置」面板
  - 退出应用


## 技术栈

- Swift + AppKit (Cocoa)
- AVFoundation（音频录制）
- Alamofire（网络与多段表单上传）
- 文件持久化（Codable + FileManager）


## 深度文档

**核心模块**（架构参考）：
- `Others/Model/SettingsInfo.swift`：全局配置自动持久化
- `Others/Tool/AudioRecordTool.swift`：录音与时长验证
- `Others/Network/HttpDigger*.swift`：ASR 服务商集成


## 快速开始

### 前置条件

- macOS 10.14 Mojave 或更新版本
- Xcode 12.0 或更新版本
- ASR 服务商的 API Key（OpenAI 或 智谱）

### 运行步骤

**1. 克隆与打开**
```bash
git clone https://github.com/QuanchaoSong/luzhiming.git
cd luzhiming
open luzhiming.xcodeproj
```

**2. 在 Xcode 中**
- 选择方案（Scheme）：`luzhiming`
- 选择目标：`My Mac`
- 按 `Cmd + R` 运行

**3. 配置 API Key**
首次启动时，点击菜单栏图标 → 「设置」，选择 ASR 服务商并输入 API Key。

或直接编辑本地配置文件：
```bash
# OpenAI
echo "sk-..." > ~/.luzhiming/key_files/openai_api_key

# 智谱
echo "..." > ~/.luzhiming/key_files/zhipu_api_key
```

**4. 开始使用**
- 点击悬浮圆形按钮开始录音
- 再次点击结束录音
- 结果自动进入剪贴板 ✨


## 设置与持久化

- 全局设置模型：`SettingsInfo`
- 自动保存位置：`~/.luzhiming/settings.json`
- 设置面板包含三部分：
  1. **API Keys**：服务商选择 + Key 管理
  2. **Time Settings**：最短/最长录音时长配置
  3. **Cache Management**：历史录音数量上限与自动清理

更多详情见 [`SETTINGS_USAGE.md`](./SETTINGS_USAGE.md)。


## 录音与时长控制

- **音频格式**：WAV（16kHz，PCM，单声道）
- **计时精度**：0.1s
- **时长限制**：由设置面板可配
- **自动丢弃**：短于最短时长的录音自动删除
- **文件位置**：`~/.luzhiming/audio_recordings/recording_YYYYMMDD_HHmmss.wav`

更多详情见 [`AUDIO_RECORDING_USAGE.md`](./AUDIO_RECORDING_USAGE.md)。


## 语音识别服务（ASR）

### 支持的服务商

| 服务商 | 模型 | 格式支持 | 时间戳 | 状态 |
|------|------|--------|------|------|
| **OpenAI** | whisper-1, gpt-4o-transcribe, gpt-4o-mini-transcribe | json/text/srt/vtt/verbose_json | ✅ | ✅ 已接入 |
| **智谱** | GLM-ASR | json | ✅ | ✅ 已接入 |
| **Doubao** | — | — | — | 📋 计划中 |

### 快速选择

在设置 → API Keys 中选择服务商，`MainVC` 会自动路由到对应实现。

详情与高级参数见 [`OPENAI_ASR_USAGE.md`](./OPENAI_ASR_USAGE.md)。


## 本地存储与安全

- 所有设置与密钥都存储在用户目录，不依赖 Keychain 或 UserDefaults：
  - 设置：`~/.luzhiming/settings.json`
  - 密钥：`~/.luzhiming/key_files/{provider}_api_key`
  - 录音：`~/.luzhiming/audio_recordings/`
- 请勿将密钥提交到版本库；`.gitignore` 已排除


## 权限与兼容性

- 需要麦克风权限（首次运行会弹窗）
- 仅限 macOS（Catalina 及以上通常可用；建议使用最新 Xcode 测试）


## 疑难排查

| 问题 | 解决方案 |
|------|--------|
| 缺少 API Key | 在「设置」中配置或编辑 `~/.luzhiming/key_files/` |
| 麦克风无权限 | 系统设置 → 安全性与隐私 → 麦克风，授予权限 |
| 文件超过 25MB | 请缩短录音或压缩音频格式 |
| 转写超时 | 检查网络连接或稍后重试（API 频率限制） |
| 转写失败 | 查看系统日志或确认 API Key 余额充足 |
| 录音过短被丢弃 | 在设置中调低「最短录音时长」 |


## 路线图（Roadmap）

- [ ] 接入 Doubao/字节系 ASR
- [ ] UI 反馈增强（状态提示、错误提示）
- [ ] 悬浮按钮显示计时/剩余时长
- [ ] 更丰富的导出能力（SRT/VTT 文件直存）


## 许可证

本项目采用 **AGPL-3.0** 协议，禁止商业盈利使用与闭源二次开发。

| 行为 | 允许 |
|------|------|
| 个人学习、研究 | ✅ |
| 开源社区贡献 | ✅ |
| 学术研究 | ✅ |
| **商业产品、付费服务** | ❌ |
| **闭源二次开发** | ❌ |
| **网络服务规避条款** | ❌ |

**关键条款**：即使仅在云服务上运行而不分发代码，也必须向用户提供修改代码的权利。

详见 [`LICENSE`](./LICENSE) 文件及 [AGPL-3.0 官方文档](https://www.gnu.org/licenses/agpl-3.0.html)。

---

## 贡献与反馈

欢迎提交以下内容：
- 🐛 Bug 报告与修复
- ✨ 功能建议与实现
- 📝 文档完善
- 🌐 翻译与本地化

请通过 [GitHub Issues](https://github.com/QuanchaoSong/luzhiming/issues) 或 [Discussions](https://github.com/QuanchaoSong/luzhiming/discussions) 反馈。

## 致谢

感谢以下开源项目与服务的支持：
- [Alamofire](https://github.com/Alamofire/Alamofire)：HTTP 网络库
- OpenAI、智谱 AI 的公开 API 文档与开发者社区
- macOS 开发社区的最佳实践分享
