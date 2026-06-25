FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.unique.cell_phone }
    email { Faker::Internet.unique.email }
    password { 'yoga123456' }
    password_confirmation { 'yoga123456' }
    role { :member }

    trait :teacher do
      role { :teacher }
      bio { '资深瑜伽导师' }
    end
  end
end
