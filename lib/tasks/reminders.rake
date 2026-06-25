namespace :reminders do
  desc "发送开课前2小时提醒通知. 使用: rake reminders:send_class_reminders"
  task send_class_reminders: :environment do
    puts "===== 开始发送课程开课提醒 ====="
    puts "当前时间: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"

    reminder_window_start = 2.hours.from_now
    reminder_window_end = 1.hour.from_now

    puts "扫描 #{reminder_window_start.strftime('%Y-%m-%d %H:%M')} 到 #{reminder_window_end.strftime('%Y-%m-%d %H:%M')} 之间开课的课程..."

    courses = Course.where(start_time: reminder_window_start..reminder_window_end)
    puts "找到 #{courses.count} 门即将开课的课程"

    notified_count = 0
    skipped_count = 0

    courses.each do |course|
      puts "\n处理课程: #{course.name} (#{course.start_time.strftime('%Y-%m-%d %H:%M')})"

      confirmed_bookings = course.confirmed_bookings.where(reminder_sent_at: nil).includes(:user)
      puts "  未提醒人数: #{confirmed_bookings.count}"

      confirmed_bookings.each do |booking|
        user = booking.user

        begin
          NotificationService.create_reminder_notification(user, course)
          booking.update!(reminder_sent_at: Time.now)
          notified_count += 1
          puts "  - ✓ 已提醒 #{user.name}"
        rescue StandardError => e
          Rails.logger.error "Failed to send reminder to user #{user.id} for course #{course.id}: #{e.message}"
          puts "  - ✗ 提醒失败 #{user.name}: #{e.message}"
        end
      end

      already_sent_count = course.confirmed_bookings.where.not(reminder_sent_at: nil).count
      if already_sent_count > 0
        puts "  已提醒过: #{already_sent_count} 人（跳过）"
        skipped_count += already_sent_count
      end
    end

    puts "\n===== 提醒发送完成 ====="
    puts "成功发送: #{notified_count} 条"
    puts "重复跳过: #{skipped_count} 条"
    puts "总计: #{notified_count + skipped_count} 条"
  end
end
