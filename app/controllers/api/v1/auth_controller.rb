module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:register, :login]

      def register
        role = params[:role] || 'member'
        unless %w[member teacher].include?(role)
          return render json: { error: 'Invalid role' }, status: :bad_request
        end

        @user = User.new(user_params.merge(role: role))

        if @user.save
          if params[:membership_type].present?
            create_membership(@user, params)
          end

          token = JsonWebToken.encode(user_id: @user.id)
          render json: {
            token: token,
            user: UserSerializer.new(@user).as_json
          }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        @user = User.find_by(phone: params[:phone]) || User.find_by(email: params[:phone])

        if @user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: @user.id)
          render json: {
            token: token,
            user: UserSerializer.new(@user).as_json
          }, status: :ok
        else
          render json: { error: 'Invalid phone/email or password' }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:name, :phone, :email, :password, :password_confirmation, :bio)
      end

      def create_membership(user, params)
        membership_type = params[:membership_type]
        start_date = params[:start_date]&.to_date || Date.today

        if membership_type == 'punch_card'
          total_classes = params[:total_classes]&.to_i || 10
          end_date = params[:end_date]&.to_date || 1.year.from_now.to_date
          user.memberships.create!(
            membership_type: :punch_card,
            total_classes: total_classes,
            remaining_classes: total_classes,
            start_date: start_date,
            end_date: end_date
          )
        elsif membership_type == 'yearly'
          end_date = params[:end_date]&.to_date || 1.year.from_now.to_date
          user.memberships.create!(
            membership_type: :yearly,
            start_date: start_date,
            end_date: end_date
          )
        end
      end
    end
  end
end
