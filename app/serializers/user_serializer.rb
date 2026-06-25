class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :email, :role, :bio, :created_at, :unread_count

  has_many :memberships, if: :include_memberships?

  def include_memberships?
    instance_options[:include_memberships] != false
  end
end
