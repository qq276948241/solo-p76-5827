module Api
  module V1
    class CoursesController < ApplicationController
      before_action :set_course, only: [:show, :book, :cancel]

      def index
        @courses = if params[:date].present?
                     date = Date.parse(params[:date])
                     Course.by_date_range(date, date)
                   elsif params[:start_date].present? && params[:end_date].present?
                     Course.by_date_range(Date.parse(params[:start_date]), Date.parse(params[:end_date]))
                   else
                     Course.upcoming
                   end

        @courses = @courses.page(params[:page] || 1).per(params[:per_page] || 20)

        render json: @courses, each_serializer: CourseSerializer, meta: pagination_meta(@courses)
      end

      def show
        render json: @course, serializer: CourseSerializer
      end

      def book
        authorize_member!

        service = BookingService.new(current_user, @course)

        begin
          result = service.book!
          if result.is_a?(Hash) && result[:waitlist]
            render json: {
              message: 'Course is full. You have been added to the waitlist.',
              booking: BookingSerializer.new(result[:booking]).as_json,
              waitlist: WaitlistSerializer.new(result[:waitlist]).as_json
            }, status: :accepted
          else
            render json: {
              message: 'Booking confirmed successfully!',
              booking: BookingSerializer.new(result).as_json
            }, status: :created
          end
        rescue BookingService::BookingError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      def cancel
        authorize_member!

        service = BookingService.new(current_user, @course)

        begin
          booking = service.cancel!
          render json: {
            message: 'Booking cancelled successfully!',
            booking: BookingSerializer.new(booking).as_json
          }, status: :ok
        rescue BookingService::BookingError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      private

      def set_course
        @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Course not found' }, status: :not_found
      end

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
