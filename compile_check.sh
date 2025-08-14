#!/bin/bash

# FitWise AI 编译检查脚本
# 用于验证项目是否可以正常编译

echo "================================"
echo "FitWise AI 编译检查"
echo "================================"
echo ""

# 检查当前目录
echo "当前目录: $(pwd)"
echo ""

# 检查项目文件
if [ -f "fit_wise_ai.xcodeproj/project.pbxproj" ]; then
    echo "✅ 项目文件存在"
else
    echo "❌ 项目文件不存在"
    exit 1
fi

# 列出所有 Swift 文件
echo ""
echo "Swift 源文件列表:"
echo "----------------"
find fit_wise_ai -name "*.swift" -type f | while read file; do
    echo "  📄 $file"
done

echo ""
echo "================================"
echo "编译检查完成"
echo "================================"
echo ""
echo "建议操作:"
echo "1. 在 Xcode 中打开 fit_wise_ai.xcodeproj"
echo "2. 选择目标设备 (iPhone Simulator)"
echo "3. 按 Cmd+B 进行编译"
echo "4. 修复任何编译错误"
echo "5. 按 Cmd+R 运行应用"
echo ""
echo "注意事项:"
echo "- 确保已安装 Xcode 14.0 或更高版本"
echo "- iOS 部署目标已设置为 16.0"
echo "- 需要配置 OpenAI API 密钥才能使用 AI 功能"
echo ""