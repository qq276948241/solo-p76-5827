# 瑜伽工作室课程预约API

这是一个基于 Ruby on Rails 7 API 模式构建的瑜伽工作室课程预约系统后端。

## 功能特性

### 会员功能
- 手机号/邮箱注册登录（JWT认证）
- 浏览课表（按日期、日期范围筛选，分页）
- 预约课程（自动检测容量）
- 满员自动加入候补队列
- 开课前2小时可免费取消预约
- 次卡自动扣课时，取消自动返还
- 查看个人预约记录

### 会员卡体系
- **次卡 (punch_card)**：按次扣课时，预约扣1次，取消返还
- **年卡 (yearly)**：不限次数，有效期内任意预约

### 老师功能
- 查看今日/指定日期的课程安排
- 查看每节课的预约学员名单
- 学员签到（单个/批量）
- 查看签到状态

### 数据导入
- Rake任务批量导入会员CSV
- Rake任务批量导入课程CSV
- 一键导入所有数据

## 项目结构

```
app/
├── controllers/
│   ├── application_controller.rb          # 基础控制器（JWT认证）
│   └── api/v1/
│       ├── auth_controller.rb             # 注册登录
│       ├── courses_controller.rb          # 课程浏览/预约/取消
│       ├── bookings_controller.rb         # 我的预约
│       └── teacher/
│           ├── courses_controller.rb      # 老师课程管理
│           └── attendances_controller.rb  # 签到管理
├── models/
│   ├── user.rb                            # 用户（会员/老师/管理员）
│   ├── membership.rb                      # 会员卡
│   ├── course.rb                          # 课程
│   ├── booking.rb                         # 预约记录
│   ├── waitlist.rb                        # 候补队列
│   └── attendance.rb                      # 签到记录
├── services/
│   └── booking_service.rb                 # 预约核心业务逻辑
└── serializers/                            # JSON序列化器

lib/
├── json_web_token.rb                      # JWT编解码
└── tasks/
    └── import.rake                        # CSV导入任务
```

## 数据模型关系

- **User** 1:N **Membership** (用户有多张会员卡)
- **User** 1:N **Booking** (用户有多条预约)
- **User** 1:N **Waitlist** (用户可候补多门课)
- **User**(Teacher) 1:N **Course** (老师带多门课)
- **Course** 1:N **Booking** (课程有多条预约)
- **Course** 1:N **Waitlist** (课程有候补队列)
- **Course** 1:N **Attendance** (课程有多条签到)
- **Booking** 1:1 **Attendance** (每条预约对应一条签到)

## API 接口列表

### 认证接口
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | /api/v1/auth/register | 注册 | 否 |
| POST | /api/v1/auth/login | 登录 | 否 |

### 课程与预约接口（会员）
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | /api/v1/courses | 浏览课表 | 是 |
| GET | /api/v1/courses/:id | 课程详情 | 是 |
| POST | /api/v1/courses/:id/book | 预约课程 | 是(会员) |
| POST | /api/v1/courses/:id/cancel | 取消预约 | 是(会员) |
| GET | /api/v1/bookings | 我的预约 | 是 |
| GET | /api/v1/bookings/:id | 预约详情 | 是 |

### 老师专属接口
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | /api/v1/teacher/courses/today | 今日课程 | 是(老师) |
| GET | /api/v1/teacher/courses | 指定日期课程 | 是(老师) |
| GET | /api/v1/teacher/courses/:id | 课程详情(含名单) | 是(老师) |
| POST | /api/v1/teacher/attendances | 单个签到 | 是(老师) |
| POST | /api/v1/teacher/attendances/batch_check_in | 批量签到 | 是(老师) |

## 安装与运行

### 环境要求
- Ruby 3.1+
- Rails 7.0+
- PostgreSQL

### 步骤

```bash
# 1. 安装依赖
bundle install

# 2. 配置数据库
# 修改 config/database.yml 中的数据库连接信息

# 3. 创建数据库并执行迁移
rails db:create
rails db:migrate

# 4. 导入示例数据
rake import:all[db/seeds/sample_members.csv,db/seeds/sample_courses.csv]

# 5. 启动服务器
rails s
```

### CSV批量导入

```bash
# 只导入会员
rake import:members[/path/to/members.csv]

# 只导入课程
rake import:courses[/path/to/courses.csv]

# 导入全部
rake import:all[/path/to/members.csv,/path/to/courses.csv]
```

#### 会员CSV格式
```csv
name,phone,email,password,role,bio,membership_type,total_classes,remaining_classes,start_date,end_date
李晓明,13800000001,lixiaoming@example.com,yoga123456,member,,punch_card,20,20,2026-01-01,2026-12-31
```
- role: member / teacher / admin
- membership_type: punch_card / yearly

#### 课程CSV格式
```csv
name,description,teacher_phone,teacher_email,start_time,end_time,location,capacity,level,duration_hours
晨间哈他瑜伽,基础课程,13900000001,,2026-06-27 07:00:00,2026-06-27 08:00:00,A教室,15,beginner,1.0
```
- level: beginner / intermediate / advanced

## 核心业务规则

1. **容量限制**：课程预约数达到容量上限后，新预约自动进入候补队列
2. **候补转正式**：当有已确认预约取消时，候补队列第一位自动转为正式预约（需满足课时条件）
3. **取消规则**：开课前2小时之前可免费取消，之后无法取消
4. **课时计算**：次卡预约扣1次，取消返还1次；年卡无次数限制
5. **签到**：老师可为预约学员标记签到状态
6. **权限控制**：
   - 会员：只能预约、取消，查看自己的预约
   - 老师：只能管理自己带的课程和签到
   - 管理员：拥有所有权限

## 示例API调用

### 注册会员（带次卡）
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试用户",
    "phone": "13812345678",
    "password": "yoga123456",
    "password_confirmation": "yoga123456",
    "role": "member",
    "membership_type": "punch_card",
    "total_classes": 20
  }'
```

### 登录
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13812345678",
    "password": "yoga123456"
  }'
```

### 预约课程
```bash
curl -X POST http://localhost:3000/api/v1/courses/1/book \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 老师查看今日课程
```bash
curl -X GET http://localhost:3000/api/v1/teacher/courses/today \
  -H "Authorization: Bearer TEACHER_JWT_TOKEN"
```

### 批量签到
```bash
curl -X POST http://localhost:3000/api/v1/teacher/attendances/batch_check_in \
  -H "Authorization: Bearer TEACHER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": 1,
    "user_ids": [1, 2, 3]
  }'
```
