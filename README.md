# 证件管理器 (Identity Manager)

一个基于HarmonyOS的智能证件管理应用，支持证件拍照、识别、存储和管理。

## 功能特性

### 🔍 核心功能
- **证件拍照与相册选择**: 支持拍照上传和从相册选择图片
- **智能文档识别**: 调用后端API进行文档类型识别和信息提取
- **动态表单渲染**: 根据识别结果动态生成表单字段
- **本地数据库存储**: 使用HarmonyOS Preferences进行数据持久化
- **动态标签页**: 根据存储的文档类型动态生成分类标签页

### 📱 用户界面
- **现代化UI设计**: 采用Material Design风格
- **响应式布局**: 适配不同屏幕尺寸
- **流畅动画**: 提供良好的用户体验
- **多步骤流程**: 清晰的上传和识别流程

### 🔧 技术特性
- **ArkTS开发**: 使用HarmonyOS原生开发语言
- **声明式UI**: 基于ArkUI框架构建
- **状态管理**: 使用@State进行组件状态管理
- **路由系统**: 支持页面间导航和参数传递
- **权限管理**: 完善的相机和存储权限处理

## 页面结构

### 主要页面
- **Index.ets**: 主页面，显示证件列表和动态标签页
- **UploadPage.ets**: 上传页面，支持拍照、预览、识别和保存
- **EditPage.ets**: 编辑页面，用于修改证件信息
- **PrintPage.ets**: 打印页面，提供打印功能
- **DocumentDetailPage.ets**: 详情页面，显示证件详细信息
- **SettingsPage.ets**: 设置页面，应用配置

### 核心组件
- **DocumentManager**: 文档管理器，处理CRUD操作
- **LocalDatabaseManager**: 本地数据库管理器，数据持久化
- **DocumentRecognitionService**: 文档识别服务，API调用
- **ImageUtils**: 图片处理工具，拍照和相册选择
- **PermissionUtils**: 权限管理工具
- **DocumentUtils**: 文档工具类，提供辅助功能

## 项目结构

```
entry/src/main/ets/
├── pages/                    # 页面文件
│   ├── Index.ets            # 主页面
│   ├── UploadPage.ets       # 上传页面
│   ├── EditPage.ets         # 编辑页面
│   ├── PrintPage.ets        # 打印页面
│   ├── DocumentDetailPage.ets # 详情页面
│   └── SettingsPage.ets     # 设置页面
├── model/                   # 数据模型
│   ├── DocumentItem.ets     # 文档项模型
│   └── DocumentType.ets     # 文档类型枚举
├── manager/                 # 管理器
│   ├── DocumentManager.ets  # 文档管理器
│   └── LocalDatabaseManager.ets # 本地数据库管理器
├── services/                # 服务层
│   └── DocumentRecognitionService.ets # 文档识别服务
├── utils/                   # 工具类
│   ├── DocumentUtils.ets    # 文档工具
│   ├── PermissionUtils.ets  # 权限工具
│   └── ImageUtils.ets       # 图片工具
├── types/                   # 类型定义
│   ├── RouterParams.ets     # 路由参数类型
│   └── DocumentRecognition.ets # 文档识别类型
└── entryability/            # 应用入口
    └── EntryAbility.ets     # 主入口
```

## 使用说明

### 添加证件
1. 点击主页面的"+"按钮
2. 选择拍照或从相册选择
3. 预览图片
4. 等待识别完成
5. 确认识别结果并保存

### 管理证件
- **查看**: 点击证件卡片查看详情
- **编辑**: 点击"编辑"按钮修改信息
- **打印**: 点击"打印"按钮进行打印
- **搜索**: 使用搜索栏快速查找
- **分类**: 使用动态标签页按类型筛选

### 权限设置
应用需要以下权限：
- **相机权限**: 用于拍照功能
- **存储权限**: 用于访问相册和保存图片
- **网络权限**: 用于文档识别API调用

## 技术实现

### 数据模型
```typescript
export class DocumentItem {
  id: string
  name: string
  type: string
  number: string
  expiryDate: string
  imageUrl: Resource
  createTime: Date
  updateTime: Date
  dynamicFields: Map<string, string>  // 动态表单字段
  recognitionConfidence: number       // 识别置信度
  originalImagePath: string           // 原始图片路径
}
```

### 本地存储
使用HarmonyOS Preferences API进行数据持久化：
- 文档列表存储
- 文档类型统计
- 用户偏好设置

### 文档识别
- 调用后端API进行文档识别
- 支持多种文档类型（身份证、护照、驾驶证、银行卡）
- 返回结构化的识别结果
- 动态生成表单字段

### 动态标签页
- 根据存储的文档类型动态生成标签页
- 显示各类型文档数量
- 支持实时更新

## 开发环境

- **HarmonyOS SDK**: 4.0.0+
- **DevEco Studio**: 4.0.0+
- **Node.js**: 16.0.0+
- **TypeScript**: 4.9.0+

## 构建和运行

1. 克隆项目
```bash
git clone [repository-url]
cd IdentityManager
```

2. 安装依赖
```bash
npm install
```

3. 在DevEco Studio中打开项目

4. 配置设备或模拟器

5. 运行应用

## 配置说明

### 权限配置
在`entry/src/main/module.json5`中配置所需权限：
```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.CAMERA",
      "reason": "用于拍照功能"
    },
    {
      "name": "ohos.permission.READ_MEDIA",
      "reason": "用于访问相册"
    },
    {
      "name": "ohos.permission.WRITE_MEDIA",
      "reason": "用于保存图片"
    }
  ]
}
```

### API配置
在`DocumentRecognitionService.ets`中配置后端API地址：
```typescript
private static readonly API_BASE_URL = 'https://your-api-domain.com'
```

## 更新日志

### v1.0.4 (最新)
- ✨ 新增拍照和相册选择功能
- ✨ 新增文档识别功能（模拟API）
- ✨ 新增动态表单渲染
- ✨ 新增本地数据库存储
- ✨ 新增动态标签页功能
- 🔧 优化图片处理流程
- 🔧 改进权限管理
- 🐛 修复多个已知问题

### v1.0.3
- 🔧 更新路由API，使用`this.getUIContext().getRouter()`
- 🔧 更新对话框API，使用`this.getUIContext().showAlertDialog`
- 🐛 修复HarmonyOS 18兼容性问题

### v1.0.2
- 🔧 修复类型检查错误
- ✨ 新增`RouterParams.ets`类型定义文件
- 🔧 移除`any`类型使用
- 🐛 修复`router.getParams()`返回类型问题

### v1.0.1
- 🔧 修复`AlertDialog.show`弃用问题
- ✨ 新增`PermissionUtils.ets`权限管理工具
- 🔧 改进权限申请流程
- 📝 更新文档和示例

### v1.0.0
- 🎉 初始版本发布
- ✨ 基础证件管理功能
- ✨ 编辑和打印功能
- ✨ 页面导航系统
- ✨ 证件详情页面

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 联系方式

- 项目维护者: [Your Name]
- 邮箱: [your.email@example.com]
- 项目链接: [https://github.com/yourusername/IdentityManager]

## 致谢

感谢HarmonyOS开发团队提供的优秀开发框架和工具。 