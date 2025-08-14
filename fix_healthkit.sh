#!/bin/bash

# HealthKit集成修复脚本
# 用于验证和修复FitWise AI的HealthKit配置问题

echo "🔧 FitWise AI HealthKit集成修复脚本"
echo "===================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_PATH="fit_wise_ai.xcodeproj"
PLIST_PATH="fit_wise_ai/Info.plist"
ENTITLEMENTS_PATH="fit_wise_ai/fit_wise_ai.entitlements"

echo ""
echo "1️⃣  验证项目文件..."

# 检查Info.plist
if [ -f "$PLIST_PATH" ]; then
    echo -e "${GREEN}✅ Info.plist 文件存在${NC}"
    
    # 检查HealthKit权限描述
    if grep -q "NSHealthShareUsageDescription" "$PLIST_PATH"; then
        echo -e "${GREEN}✅ NSHealthShareUsageDescription 已配置${NC}"
    else
        echo -e "${RED}❌ NSHealthShareUsageDescription 缺失${NC}"
    fi
    
    if grep -q "NSHealthUpdateUsageDescription" "$PLIST_PATH"; then
        echo -e "${GREEN}✅ NSHealthUpdateUsageDescription 已配置${NC}"
    else
        echo -e "${YELLOW}⚠️  NSHealthUpdateUsageDescription 缺失（可选）${NC}"
    fi
else
    echo -e "${RED}❌ Info.plist 文件不存在${NC}"
fi

# 检查Entitlements
if [ -f "$ENTITLEMENTS_PATH" ]; then
    echo -e "${GREEN}✅ Entitlements 文件存在${NC}"
    
    if grep -q "com.apple.developer.healthkit" "$ENTITLEMENTS_PATH"; then
        echo -e "${GREEN}✅ HealthKit entitlement 已配置${NC}"
    else
        echo -e "${RED}❌ HealthKit entitlement 缺失${NC}"
    fi
else
    echo -e "${RED}❌ Entitlements 文件不存在${NC}"
fi

echo ""
echo "2️⃣  清理Xcode缓存..."

# 清理派生数据
DERIVED_DATA_PATH=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED_DATA_PATH" ]; then
    echo "清理派生数据..."
    rm -rf "$DERIVED_DATA_PATH"/fit_wise_ai-*
    echo -e "${GREEN}✅ 派生数据已清理${NC}"
else
    echo -e "${YELLOW}⚠️  派生数据目录不存在${NC}"
fi

echo ""
echo "3️⃣  构建项目..."

# 使用xcodebuild构建项目
echo "开始构建项目（这可能需要几分钟）..."
xcodebuild -project "$PROJECT_PATH" \
           -scheme "fit_wise_ai" \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           clean build 2>&1 | grep -E "(error|warning|SUCCESS|FAILED)" | tail -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ 项目构建成功${NC}"
else
    echo -e "${RED}❌ 项目构建失败，请检查错误信息${NC}"
fi

echo ""
echo "4️⃣  生成诊断报告..."

cat << EOF > healthkit_diagnostic.log
=== HealthKit集成诊断报告 ===
生成时间: $(date)

配置检查:
- Info.plist: $([ -f "$PLIST_PATH" ] && echo "✅ 存在" || echo "❌ 缺失")
- Entitlements: $([ -f "$ENTITLEMENTS_PATH" ] && echo "✅ 存在" || echo "❌ 缺失")
- NSHealthShareUsageDescription: $(grep -q "NSHealthShareUsageDescription" "$PLIST_PATH" && echo "✅ 已配置" || echo "❌ 未配置")
- NSHealthUpdateUsageDescription: $(grep -q "NSHealthUpdateUsageDescription" "$PLIST_PATH" && echo "✅ 已配置" || echo "❌ 未配置")
- HealthKit Entitlement: $(grep -q "com.apple.developer.healthkit" "$ENTITLEMENTS_PATH" && echo "✅ 已配置" || echo "❌ 未配置")

建议操作:
1. 在真机上测试应用
2. 在健康App中检查权限授予状态
3. 确保Apple Watch数据已同步
4. 如果问题持续，尝试删除并重新安装应用

EOF

echo -e "${GREEN}✅ 诊断报告已生成: healthkit_diagnostic.log${NC}"

echo ""
echo "5️⃣  后续步骤..."
echo "1. 在Xcode中打开项目"
echo "2. 选择真机作为运行目标（HealthKit在模拟器上功能受限）"
echo "3. 运行应用并在iPhone健康App中授予权限"
echo "4. 检查健康App -> 共享 -> 应用和服务中是否出现'健身智慧AI'"

echo ""
echo "✨ 修复脚本执行完成！"
echo "如果问题仍然存在，请查看 healthkit_diagnostic.log 文件获取更多信息。"