FactoryBot.define do
  factory :waitlist do
    user
    course
    position { 1 }
    active { true }
  end
end
