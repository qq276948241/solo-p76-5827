FactoryBot.define do
  factory :notification do
    user
    title { '测试通知' }
    body { '这是一条测试通知内容' }
    notifiable_type { 'Course' }
    notifiable_id { 1 }
    read_at { nil }
  end
end
