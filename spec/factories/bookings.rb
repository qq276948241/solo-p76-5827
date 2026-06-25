FactoryBot.define do
  factory :booking do
    user
    course
    status { :confirmed }
    reminder_sent_at { nil }
  end
end
