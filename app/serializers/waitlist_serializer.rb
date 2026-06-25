class WaitlistSerializer < ActiveModel::Serializer
  attributes :id, :position, :active, :created_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :course, serializer: CourseSerializer
end
