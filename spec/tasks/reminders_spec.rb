require 'rails_helper'

RSpec.describe 'Reminder Rake Task', type: :task do
  let(:teacher) { create(:user, :teacher) }
  let(:course) do
    create(:course,
           teacher: teacher,
           start_time: 110.minutes.from_now,
           end_time: 170.minutes.from_now)
  end
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:membership1) { create(:membership, user: user1) }
  let(:membership2) { create(:membership, user: user2) }
  let(:membership3) { create(:membership, user: user3) }

  before do
    membership1
    membership2
    membership3
  end

  describe 'reminders:send_class_reminders' do
    let(:run_task) { Rake::Task['reminders:send_class_reminders'].execute }

    before do
      Rake.application.rake_require 'tasks/reminders'
      Rake::Task.define_task(:environment)
    end

    context '同一课程被多名会员预约' do
      let!(:booking1) { create(:booking, user: user1, course: course, status: :confirmed) }
      let!(:booking2) { create(:booking, user: user2, course: course, status: :confirmed) }
      let!(:booking3) { create(:booking, user: user3, course: course, status: :confirmed) }

      it '所有会员都能收到通知' do
        expect { run_task }.to change { Notification.count }.by(3)

        expect(user1.notifications.where(title: '课程即将开始').count).to eq(1)
        expect(user2.notifications.where(title: '课程即将开始').count).to eq(1)
        expect(user3.notifications.where(title: '课程即将开始').count).to eq(1)
      end

      it '所有booking的reminder_sent_at都被更新' do
        run_task

        expect(booking1.reload.reminder_sent_at).not_to be_nil
        expect(booking2.reload.reminder_sent_at).not_to be_nil
        expect(booking3.reload.reminder_sent_at).not_to be_nil
      end
    end

    context '重复执行rake任务' do
      let!(:booking) { create(:booking, user: user1, course: course, status: :confirmed) }

      it '不会发重复通知' do
        expect { run_task }.to change { Notification.count }.by(1)
        expect { run_task }.not_to change { Notification.count }

        expect(user1.notifications.where(title: '课程即将开始').count).to eq(1)
      end

      it '重复执行后reminder_sent_at保持不变' do
        run_task
        first_sent_at = booking.reload.reminder_sent_at

        travel 5.minutes do
          run_task
          expect(booking.reload.reminder_sent_at).to be_within(1.second).of(first_sent_at)
        end
      end
    end

    context '会员取消后重新预约' do
      let!(:old_booking) { create(:booking, user: user1, course: course, status: :confirmed, reminder_sent_at: 1.hour.ago) }

      before do
        travel_to 10.minutes.ago do
          old_booking.update!(status: :cancelled, cancelled_at: Time.now)
        end
      end

      let!(:new_booking) { create(:booking, user: user1, course: course, status: :confirmed) }

      it '新预约的reminder_sent_at为nil，重新预约后能正常收到提醒' do
        expect(new_booking.reminder_sent_at).to be_nil
        expect(old_booking.reminder_sent_at).not_to be_nil

        expect { run_task }.to change { Notification.count }.by(1)
        expect(user1.notifications.where(title: '课程即将开始').count).to eq(1)
        expect(new_booking.reload.reminder_sent_at).not_to be_nil
      end
    end

    context '会员在收到提醒之后取消预约' do
      let!(:booking) { create(:booking, user: user1, course: course, status: :confirmed, reminder_sent_at: 1.hour.ago) }
      let!(:notification) { create(:notification, user: user1, title: '课程即将开始', notifiable: course) }

      before do
        booking.update!(status: :cancelled, cancelled_at: Time.now)
      end

      it 'reminder_sent_at不需要清理' do
        expect(booking.reload.reminder_sent_at).not_to be_nil
      end
    end

    context '只有confirmed状态的booking才会收到提醒' do
      let!(:booking_confirmed) { create(:booking, user: user1, course: course, status: :confirmed) }
      let!(:booking_waitlisted) { create(:booking, user: user2, course: course, status: :waitlisted) }
      let!(:booking_cancelled) { create(:booking, user: user3, course: course, status: :cancelled) }

      it '只处理confirmed的booking' do
        expect { run_task }.to change { Notification.count }.by(1)
        expect(user1.notifications.where(title: '课程即将开始').count).to eq(1)
        expect(user2.notifications.where(title: '课程即将开始').count).to eq(0)
        expect(user3.notifications.where(title: '课程即将开始').count).to eq(0)
      end
    end
  end

  describe 'BookingService重新预约' do
    let(:course2) { create(:course, teacher: teacher, start_time: 2.days.from_now, end_time: 3.days.from_now) }

    context '用户取消后重新预约新时段课程' do
      it '新booking的reminder_sent_at重置为nil' do
        service1 = BookingService.new(user1, course)
        booking1 = service1.create_booking!
        expect(booking1.reminder_sent_at).to be_nil

        booking1.update!(reminder_sent_at: Time.now)
        expect(booking1.reload.reminder_sent_at).not_to be_nil

        service1.cancel!

        service2 = BookingService.new(user1, course2)
        booking2 = service2.book!
        expect(booking2.reminder_sent_at).to be_nil
      end
    end
  end
end
