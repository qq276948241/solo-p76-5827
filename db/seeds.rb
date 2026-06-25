# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
puts "数据库种子任务已加载。使用 rake import:all[db/seeds/sample_members.csv,db/seeds/sample_courses.csv] 导入示例数据"
