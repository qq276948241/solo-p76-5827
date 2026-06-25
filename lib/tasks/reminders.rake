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

        existing_reminder = user.notifications.find_by(
          notifiable_type: 'Course',
          notifiable_id: course.id,
          title: '课程即将开始'
        )

        if existing_reminder
          skipped_count += 1
          puts "  - 跳过 #{user.name}: 已发送过提醒"
          next
        end

        user.notifications.create!(
          title: '课程即将开始',
          body: "温馨提醒：您预约的「#{course.name}」课程将于2小时后开始（#{course.start_time.strftime('%m月%d日 %H:%M')}），地点：#{course.location || '请查看课表'}。请准时参加~",
          notifiable: course
        )

        notified_count += 1
        puts "  - ✓ 已提醒 #{user.name}"
      end
    end

    puts "\n===== 提醒发送完成 ====="
    puts "成功发送: #{notified_count} 条"
    puts "重复跳过: #{skipped_count} 条"
    puts "总计: #{notified_count + skipped_count} 条"
  end
end
