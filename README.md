# FitWise AI 🏃‍♂️💪

<div align="center">

![FitWise AI](https://img.shields.io/badge/iOS-FitWise%20AI-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-16.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-purple.svg)

**智能健身助手 · 让AI成为你的专属健康顾问**

*An intelligent fitness companion powered by AI to provide personalized health guidance*

[English](#english) | [中文](#中文)

</div>

---

## 中文

### 📱 项目介绍

FitWise AI 是一款基于云端人工智能的iOS健康管理应用，专注于为用户提供个性化的健身指导和健康建议。通过深度集成HealthKit框架，应用能够实时分析用户的健康数据，并利用OpenAI先进的GPT技术，为用户提供精准的运动、营养和休息建议。

### ✨ 主要特性

- 🧠 **云端AI智能分析**：基于OpenAI GPT技术的先进健康数据分析
- 📊 **健康数据集成**：无缝集成iOS HealthKit获取完整健康数据
- 🎯 **个性化建议**：AI生成精准的运动、营养和休息指导方案
- 📈 **数据可视化**：直观展示健康趋势和进展
- 🌐 **智能降级**：网络不可用时提供高质量离线建议
- 🎨 **现代化UI**：采用SwiftUI构建的流畅用户界面
- 📱 **原生体验**：完全原生iOS应用，性能优异
- 🔒 **数据安全**：健康数据仅用于AI分析，不存储在云端

### 🏗️ 技术架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI UI    │    │  OpenAI GPT AI  │    │   HealthKit     │
│   现代化界面      │────│   云端智能引擎    │────│   健康数据源      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │  网络服务层      │              │
         │              │  智能重试与降级   │              │
         │              └─────────────────┘              │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  MVVM 架构      │
                    │  数据绑定与状态管理 │
                    └─────────────────┘
```

**核心技术栈：**
- **UI框架**: SwiftUI - 声明式用户界面
- **AI引擎**: OpenAI GPT - 云端先进AI模型
- **健康数据**: HealthKit - iOS健康数据框架
- **网络层**: URLSession + 智能重试机制
- **架构模式**: MVVM - 数据驱动的响应式架构
- **开发语言**: Swift 5.9+

### 📋 系统要求

- **iOS版本**: 16.0 或更高
- **Xcode版本**: 15.0 或更高
- **Swift版本**: 5.9 或更高
- **设备支持**: iPhone/iPad (推荐iPhone以获得最佳体验)
- **权限要求**: HealthKit访问权限

### 🚀 安装指南

#### 前置要求
确保你的开发环境满足以下条件：
```bash
# 检查Xcode版本
xcodebuild -version

# 检查Swift版本
swift --version
```

#### 克隆项目
```bash
git clone https://github.com/username/fit_wise_ai.git
cd fit_wise_ai
```

#### 打开项目
```bash
# 使用Xcode打开项目
open fit_wise_ai.xcodeproj
```

#### 配置开发者账号
1. 在Xcode中选择项目
2. 进入 "Signing & Capabilities" 标签
3. 配置你的开发者团队
4. 确保Bundle Identifier唯一

#### 运行应用
1. 选择目标设备或模拟器
2. 按 `Cmd + R` 运行项目
3. 首次运行时需要授权HealthKit权限

### 📖 使用说明

#### 首次使用
1. **权限授权**: 启动应用后，系统会请求HealthKit访问权限
2. **数据同步**: 应用将自动同步你的健康数据
3. **AI分析**: 系统开始分析你的健康模式
4. **个性化建议**: 基于分析结果获得定制建议

#### 主要功能
- **首页仪表板**: 查看健康数据概览和AI建议
- **健康统计**: 详细的健康数据图表和趋势分析
- **智能建议**: 基于AI分析的个性化健身方案
- **设置中心**: 自定义应用偏好和隐私设置

### 🏗️ 项目结构详解

```
fit_wise_ai/
├── 📱 fit_wise_aiApp.swift          # 应用入口点
├── 🏠 ContentView.swift             # 主视图控制器
├── 📁 Models/                       # 数据模型层
│   ├── 🧠 AIAdvice.swift           # AI建议数据模型
│   └── 📊 HealthData.swift         # 健康数据模型
├── 🔧 Services/                     # 服务层
│   ├── 🤖 AIService.swift          # AI分析服务
│   └── 🏥 HealthKitService.swift   # HealthKit数据服务
├── 🎭 ViewModels/                   # 视图模型层
│   └── 📈 HealthDataViewModel.swift # 健康数据视图模型
├── 🎨 Views/                        # 视图层
│   ├── 🏠 HomeView.swift           # 首页视图
│   ├── ⚙️ SettingsView.swift       # 设置视图
│   └── 📦 Components/              # 可复用组件
│       └── 📊 HealthStatsView.swift # 健康统计组件
├── 🎨 Assets.xcassets/             # 资源文件
├── ℹ️ Info.plist                   # 应用配置
└── 🔐 fit_wise_ai.entitlements     # 应用权限配置
```

### 🔧 核心功能介绍

#### 1. 云端AI智能分析引擎
- **智能对话**: 基于OpenAI GPT的自然语言健康分析
- **个性化建议**: 根据用户具体数据生成定制化指导
- **多维度分析**: 综合考虑运动、营养、休息多个维度
- **实时洞察**: 即时分析当日健康数据并提供建议
- **智能降级**: 网络不可用时提供高质量离线建议

#### 2. HealthKit深度集成
- **数据获取**: 自动同步iOS健康应用数据
- **隐私保护**: 符合苹果隐私准则的数据处理
- **实时更新**: 支持健康数据的实时监控
- **多维度分析**: 综合分析步数、心率、活动消耗、运动时长等

#### 3. 网络服务层
- **智能重试**: 指数退避算法，确保API调用稳定性
- **网络监控**: 实时监测WiFi/蜂窝数据连接状态
- **错误处理**: 详细的错误分类和用户友好提示
- **降级方案**: 网络问题时自动切换到离线模式

#### 4. 用户界面与体验
- **直观设计**: 清晰易懂的健康数据展示
- **响应式布局**: 适配不同屏幕尺寸
- **流畅交互**: 基于SwiftUI的丝滑用户体验
- **智能状态**: 实时显示AI服务和网络状态

### 🛠️ 开发环境配置

#### 开发工具设置
```bash
# 安装开发依赖
# 确保安装最新版本的Xcode和Command Line Tools
xcode-select --install
```

#### 代码风格
项目遵循以下代码规范：
- Swift API设计准则
- SwiftLint代码风格检查
- 详细的代码注释和文档

#### 调试技巧
- 使用Xcode Instruments分析性能
- 通过Health应用模拟器测试HealthKit集成
- 利用Core ML模型调试工具验证AI功能

### 🤝 贡献指南

我们欢迎社区贡献！请遵循以下流程：

#### 提交代码
1. Fork项目到你的GitHub账号
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

#### 代码规范
- 遵循Swift编码规范
- 添加适当的单元测试
- 更新相关文档
- 确保所有测试通过

#### 问题报告
- 使用GitHub Issues报告Bug
- 提供详细的复现步骤
- 包含设备信息和iOS版本

### 📄 许可证信息

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

### 📞 联系方式

- **开发者**: shizeying
- **邮箱**: shizeying@joyme.sg
- **项目地址**: [GitHub Repository](https://github.com/username/fit_wise_ai)

---

## English

### 📱 Project Overview

FitWise AI is an intelligent iOS health management application powered by cloud-based AI that focuses on providing personalized fitness guidance and health recommendations. Through deep integration with the HealthKit framework, the app can analyze users' health data in real-time and utilize OpenAI's advanced GPT technology to provide precise exercise, nutrition, and rest recommendations.

### ✨ Key Features

- 🧠 **Cloud AI Intelligence**: Advanced health data analysis powered by OpenAI GPT technology
- 📊 **Health Data Integration**: Seamless integration with iOS HealthKit for comprehensive health data
- 🎯 **Personalized Recommendations**: AI-generated precise guidance for exercise, nutrition, and rest
- 📈 **Data Visualization**: Intuitive display of health trends and progress
- 🌐 **Smart Fallback**: High-quality offline recommendations when network is unavailable
- 🎨 **Modern UI**: Smooth user interface built with SwiftUI
- 📱 **Native Experience**: Fully native iOS app with excellent performance
- 🔒 **Data Security**: Health data used only for AI analysis, not stored in cloud

### 🏗️ Technical Architecture

**Core Technology Stack:**
- **UI Framework**: SwiftUI - Declarative user interface
- **AI Engine**: OpenAI GPT - Advanced cloud AI models
- **Health Data**: HealthKit - iOS health data framework
- **Network Layer**: URLSession + Smart retry mechanisms
- **Architecture Pattern**: MVVM - Data-driven reactive architecture
- **Development Language**: Swift 5.9+

### 📋 System Requirements

- **iOS Version**: 16.0 or higher
- **Xcode Version**: 15.0 or higher
- **Swift Version**: 5.9 or higher
- **Device Support**: iPhone/iPad (iPhone recommended for best experience)
- **Permission Requirements**: HealthKit access permissions

### 🚀 Installation Guide

#### Prerequisites
Ensure your development environment meets the following requirements:
```bash
# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version
```

#### Clone the Project
```bash
git clone https://github.com/username/fit_wise_ai.git
cd fit_wise_ai
```

#### Open the Project
```bash
# Open project with Xcode
open fit_wise_ai.xcodeproj
```

#### Configure Developer Account
1. Select the project in Xcode
2. Go to "Signing & Capabilities" tab
3. Configure your developer team
4. Ensure Bundle Identifier is unique

#### Run the Application
1. Select target device or simulator
2. Press `Cmd + R` to run the project
3. Grant HealthKit permissions on first launch

### 📖 Usage Instructions

#### First-time Use
1. **Permission Authorization**: The app will request HealthKit access permissions upon launch
2. **Data Synchronization**: The app will automatically sync your health data
3. **AI Analysis**: The system starts analyzing your health patterns
4. **Personalized Recommendations**: Get customized recommendations based on analysis results

#### Main Features
- **Home Dashboard**: View health data overview and AI recommendations
- **Health Statistics**: Detailed health data charts and trend analysis
- **Smart Recommendations**: Personalized fitness plans based on AI analysis
- **Settings Center**: Customize app preferences and privacy settings

### 🔧 Core Features

#### 1. AI Intelligence Analysis Engine
- **Data Processing**: Real-time analysis of user health data
- **Pattern Recognition**: Identify user health habits and trends
- **Predictive Analysis**: Predict health risks based on historical data
- **Recommendation Generation**: Generate personalized health improvement suggestions

#### 2. HealthKit Integration
- **Data Acquisition**: Automatically sync iOS Health app data
- **Privacy Protection**: Data processing compliant with Apple privacy guidelines
- **Real-time Updates**: Support real-time monitoring of health data
- **Multi-dimensional Analysis**: Comprehensive analysis of steps, heart rate, sleep, and other data

#### 3. User Interface
- **Intuitive Design**: Clear and understandable health data display
- **Responsive Layout**: Adaptive to different screen sizes
- **Smooth Interaction**: Silky user experience based on SwiftUI
- **Theme Customization**: Support for light/dark mode

### 🛠️ Development Environment Setup

#### Development Tools Setup
```bash
# Install development dependencies
# Ensure latest Xcode and Command Line Tools are installed
xcode-select --install
```

#### Code Style
The project follows these coding standards:
- Swift API Design Guidelines
- SwiftLint code style checking
- Detailed code comments and documentation

### 🤝 Contributing Guidelines

We welcome community contributions! Please follow this process:

#### Submitting Code
1. Fork the project to your GitHub account
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Create a Pull Request

#### Code Standards
- Follow Swift coding conventions
- Add appropriate unit tests
- Update relevant documentation
- Ensure all tests pass

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 📞 Contact

- **Developer**: shizeying
- **Email**: shizeying@joyme.sg
- **Project Repository**: [GitHub Repository](https://github.com/username/fit_wise_ai)

---

<div align="center">

**🌟 如果这个项目对你有帮助，请给我们一个Star！**

**🌟 If this project helps you, please give us a Star!**

Made with ❤️ by [shizeying](https://github.com/username)

</div>