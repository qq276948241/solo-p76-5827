class MembershipSerializer < ActiveModel::Serializer
  attributes :id, :membership_type, :total_classes, :remaining_classes, :start_date, :end_date, :active
end
