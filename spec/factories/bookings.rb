FactoryBot.define do
  factory :booking do
    user
    course
    status { :confirmed }
  end
end
