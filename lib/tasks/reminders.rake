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

      confirmed_bookings = course.confirmed_bookings.includes(:user)
      puts "  已预约人数: #{confirmed_bookings.count}"

      confirmed_bookings.each do |booking|
        user = booking.user

        if NotificationService.reminder_already_sent?(user, course)
          skipped_count += 1
          puts "  - 跳过 #{user.name}: 已发送过提醒"
          next
        end

        begin
          NotificationService.create_reminder_notification(user, course)
          notified_count += 1
          puts "  - ✓ 已提醒 #{user.name}"
        rescue StandardError => e
          Rails.logger.error "Failed to send reminder to user #{user.id} for course #{course.id}: #{e.message}"
          puts "  - ✗ 提醒失败 #{user.name}: #{e.message}"
        end
      end
    end

    puts "\n===== 提醒发送完成 ====="
    puts "成功发送: #{notified_count} 条"
    puts "重复跳过: #{skipped_count} 条"
    puts "总计: #{notified_count + skipped_count} 条"
  end
end
