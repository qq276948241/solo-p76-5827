require 'rails_helper'

RSpec.describe NotificationService, type: :service do
  let(:user) { create(:user) }
  let(:course) { create(:course, start_time: 3.days.from_now, end_time: 4.days.from_now) }
  let(:booking) { create(:booking, user: user, course: course) }
  let(:waitlist) { create(:waitlist, user: user, course: course, position: 1) }

  describe '.create_booking_confirmed_notification' do
    it 'creates a booking confirmed notification with correct attributes' do
      expect {
        NotificationService.create_booking_confirmed_notification(user, course, booking)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.title).to eq('预约成功')
      expect(notification.body).to include(course.name)
      expect(notification.body).to include(course.start_time.strftime('%m月%d日 %H:%M'))
      expect(notification.notifiable).to eq(booking)
    end
  end

  describe '.create_waitlist_notification' do
    it 'creates a waitlist notification with correct attributes' do
      expect {
        NotificationService.create_waitlist_notification(user, course, waitlist)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.title).to eq('已进入候补名单')
      expect(notification.body).to include(course.name)
      expect(notification.body).to include('第1位')
      expect(notification.notifiable).to eq(waitlist)
    end
  end

  describe '.create_cancellation_notification' do
    context 'when canceling a confirmed booking' do
      before { booking.update!(cancel_reason: nil) }

      it 'creates a booking cancellation notification' do
        expect {
          NotificationService.create_cancellation_notification(user, course, booking)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to eq('预约已取消')
        expect(notification.body).to include(course.name)
        expect(notification.body).to include('课时已返还')
        expect(notification.notifiable).to eq(booking)
      end
    end

    context 'when canceling a waitlisted booking' do
      before { booking.update!(cancel_reason: 'Removed from waitlist') }

      it 'creates a waitlist cancellation notification' do
        expect {
          NotificationService.create_cancellation_notification(user, course, booking)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.title).to eq('候补已取消')
        expect(notification.body).to include(course.name)
        expect(notification.body).to include('候补申请')
        expect(notification.notifiable).to eq(booking)
      end
    end
  end

  describe '.create_promotion_notification' do
    it 'creates a promotion notification with correct attributes' do
      expect {
        NotificationService.create_promotion_notification(user, course, booking)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.title).to eq('候补成功转正')
      expect(notification.body).to include(course.name)
      expect(notification.body).to include('空位')
      expect(notification.notifiable).to eq(booking)
    end
  end

  describe '.create_reminder_notification' do
    it 'creates a class reminder notification' do
      expect {
        NotificationService.create_reminder_notification(user, course)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.title).to eq('课程即将开始')
      expect(notification.body).to include(course.name)
      expect(notification.body).to include('2小时后开始')
      expect(notification.body).to include(course.location.to_s)
      expect(notification.notifiable).to eq(course)
    end

    context 'when course has no location' do
      let(:course) { create(:course, location: nil, start_time: 3.days.from_now, end_time: 4.days.from_now) }

      it 'uses default location text' do
        NotificationService.create_reminder_notification(user, course)
        notification = Notification.last
        expect(notification.body).to include('请查看课表')
      end
    end
  end

  describe '.reminder_already_sent?' do
    context 'when reminder has been sent' do
      before do
        user.notifications.create!(
          title: '课程即将开始',
          body: 'test',
          notifiable: course
        )
      end

      it 'returns true' do
        expect(NotificationService.reminder_already_sent?(user, course)).to be true
      end
    end

    context 'when reminder has not been sent' do
      it 'returns false' do
        expect(NotificationService.reminder_already_sent?(user, course)).to be false
      end
    end

    context 'when other notifications exist but not reminders' do
      before do
        user.notifications.create!(
          title: '预约成功',
          body: 'test',
          notifiable: course
        )
      end

      it 'returns false' do
        expect(NotificationService.reminder_already_sent?(user, course)).to be false
      end
    end
  end
end
