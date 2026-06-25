FactoryBot.define do
  factory :course do
    name { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    association :teacher, factory: :user, role: :teacher
    start_time { 3.days.from_now }
    end_time { 4.days.from_now }
    location { 'A教室' }
    capacity { 15 }
    level { :beginner }
    duration_hours { 1.0 }
  end
end
