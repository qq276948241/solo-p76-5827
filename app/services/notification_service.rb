class NotificationService
  def self.create_booking_confirmed_notification(user, course, booking)
    Notification.create!(
      user: user,
      title: '预约成功',
      body: "您已成功预约「#{course.name}」课程，上课时间：#{course.start_time.strftime('%m月%d日 %H:%M')}。",
      notifiable: booking
    )
  end

  def self.create_waitlist_notification(user, course, waitlist)
    Notification.create!(
      user: user,
      title: '已进入候补名单',
      body: "「#{course.name}」课程已满员，您已进入候补名单，当前排位第#{waitlist.position}位。如有空位将自动为您预约。",
      notifiable: waitlist
    )
  end

  def self.create_cancellation_notification(user, course, booking)
    if booking.cancel_reason == 'Removed from waitlist'
      Notification.create!(
        user: user,
        title: '候补已取消',
        body: "您已成功取消「#{course.name}」课程的候补申请。",
        notifiable: booking
      )
    else
      Notification.create!(
        user: user,
        title: '预约已取消',
        body: "您已成功取消「#{course.name}」课程的预约，上课时间：#{course.start_time.strftime('%m月%d日 %H:%M')}。课时已返还至您的卡内。",
        notifiable: booking
      )
    end
  end

  def self.create_promotion_notification(user, course, booking)
    Notification.create!(
      user: user,
      title: '候补成功转正',
      body: "恭喜！「#{course.name}」课程有了空位，您已从候补转为正式预约，上课时间：#{course.start_time.strftime('%m月%d日 %H:%M')}。",
      notifiable: booking
    )
  end

  def self.create_reminder_notification(user, course)
    Notification.create!(
      user: user,
      title: '课程即将开始',
      body: "温馨提醒：您预约的「#{course.name}」课程将于2小时后开始（#{course.start_time.strftime('%m月%d日 %H:%M')}），地点：#{course.location || '请查看课表'}。请准时参加~",
      notifiable: course
    )
  end

  def self.reminder_already_sent?(user, course)
    user.notifications.exists?(
      notifiable_type: 'Course',
      notifiable_id: course.id,
      title: '课程即将开始'
    )
  end
end
