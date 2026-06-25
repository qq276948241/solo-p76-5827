module Api
  module V1
    class BookingsController < ApplicationController
      def index
        status = params[:status] || 'confirmed,waitlisted'
        statuses = status.split(',').map(&:strip)

        @bookings = current_user.bookings
                                 .where(status: statuses)
                                 .includes(:course, :attendance)
                                 .order(created_at: :desc)
                                 .page(params[:page] || 1)
                                 .per(params[:per_page] || 20)

        render json: @bookings,
               each_serializer: BookingSerializer,
               include_attendance: true,
               meta: pagination_meta(@bookings)
      end

      def show
        @booking = current_user.bookings.find(params[:id])
        render json: @booking, serializer: BookingSerializer, include_attendance: true
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Booking not found' }, status: :not_found
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
