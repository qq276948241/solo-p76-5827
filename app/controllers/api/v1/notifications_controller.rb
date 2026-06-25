module Api
  module V1
    class NotificationsController < ApplicationController
      def index
        @notifications = current_user.notifications.recent

        if params[:read].present?
          if params[:read] == 'true'
            @notifications = @notifications.read
          elsif params[:read] == 'false'
            @notifications = @notifications.unread
          end
        end

        @notifications = @notifications.page(params[:page] || 1).per(params[:per_page] || 20)

        render json: @notifications,
               each_serializer: NotificationSerializer,
               meta: pagination_meta(@notifications)
      end

      def read
        @notification = current_user.notifications.find(params[:id])
        @notification.mark_as_read!

        render json: {
          message: 'Notification marked as read',
          notification: NotificationSerializer.new(@notification).as_json
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end

      private

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end
