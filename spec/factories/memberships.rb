FactoryBot.define do
  factory :membership do
    user
    membership_type { :punch_card }
    total_classes { 20 }
    remaining_classes { 20 }
    start_date { Date.today }
    end_date { 1.year.from_now }
    active { true }

    trait :yearly do
      membership_type { :yearly }
      total_classes { nil }
      remaining_classes { nil }
    end
  end
end
