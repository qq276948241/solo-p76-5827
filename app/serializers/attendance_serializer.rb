class AttendanceSerializer < ActiveModel::Serializer
  attributes :id, :checked_in, :checked_in_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :booking
end
