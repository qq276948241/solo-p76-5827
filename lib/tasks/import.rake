require 'csv'

namespace :import do
  desc "批量导入会员数据 CSV. 使用: rake import:members[file_path]"
  task :members, [:file_path] => :environment do |t, args|
    file_path = args[:file_path]
    unless File.exist?(file_path)
      puts "错误: 文件不存在 - #{file_path}"
      exit 1
    end

    puts "开始导入会员数据..."
    success_count = 0
    error_count = 0

    CSV.foreach(file_path, headers: true, encoding: 'UTF-8') do |row|
      begin
        role = row['role']&.strip || 'member'
        next unless %w[member teacher admin].include?(role)

        default_password = row['password']&.strip || 'yoga123456'

        ActiveRecord::Base.transaction do
          user = User.create!(
            name: row['name']&.strip,
            phone: row['phone']&.strip,
            email: row['email']&.strip,
            password: default_password,
            password_confirmation: default_password,
            role: role,
            bio: row['bio']&.strip
          )

          membership_type = row['membership_type']&.strip
          if membership_type.present? && %w[punch_card yearly].include?(membership_type)
            start_date = (row['start_date']&.strip&.to_date rescue Date.today) || Date.today
            end_date = (row['end_date']&.strip&.to_date rescue 1.year.from_now.to_date) || 1.year.from_now.to_date

            if membership_type == 'punch_card'
              total_classes = (row['total_classes']&.strip&.to_i rescue 10) || 10
              remaining_classes = (row['remaining_classes']&.strip&.to_i rescue total_classes) || total_classes
              Membership.create!(
                user: user,
                membership_type: :punch_card,
                total_classes: total_classes,
                remaining_classes: remaining_classes,
                start_date: start_date,
                end_date: end_date
              )
            else
              Membership.create!(
                user: user,
                membership_type: :yearly,
                start_date: start_date,
                end_date: end_date
              )
            end
          end

          success_count += 1
          puts "✓ 成功创建: #{user.name} (#{user.role}) - #{user.phone}"
        end
      rescue ActiveRecord::RecordInvalid => e
        error_count += 1
        puts "✗ 创建失败: #{row['name']} - #{e.message}"
      rescue StandardError => e
        error_count += 1
        puts "✗ 未知错误: #{row['name']} - #{e.message}"
      end
    end

    puts "\n导入完成!"
    puts "成功: #{success_count} 条"
    puts "失败: #{error_count} 条"
  end

  desc "批量导入课程数据 CSV. 使用: rake import:courses[file_path]"
  task :courses, [:file_path] => :environment do |t, args|
    file_path = args[:file_path]
    unless File.exist?(file_path)
      puts "错误: 文件不存在 - #{file_path}"
      exit 1
    end

    puts "开始导入课程数据..."
    success_count = 0
    error_count = 0

    CSV.foreach(file_path, headers: true, encoding: 'UTF-8') do |row|
      begin
        teacher_phone = row['teacher_phone']&.strip
        teacher_email = row['teacher_email']&.strip

        teacher = if teacher_phone.present?
                    User.find_by(phone: teacher_phone)
                  elsif teacher_email.present?
                    User.find_by(email: teacher_email)
                  end

        unless teacher&.teacher? || teacher&.admin?
          error_count += 1
          puts "✗ 老师不存在或不是老师角色: #{row['name']} - phone:#{teacher_phone} email:#{teacher_email}"
          next
        end

        start_time = DateTime.parse(row['start_time'].strip)
        end_time = DateTime.parse(row['end_time'].strip)
        level = (row['level']&.strip || 'beginner')
        unless %w[beginner intermediate advanced].include?(level)
          level = 'beginner'
        end

        course = Course.create!(
          name: row['name']&.strip,
          description: row['description']&.strip,
          teacher: teacher,
          start_time: start_time,
          end_time: end_time,
          location: row['location']&.strip,
          capacity: (row['capacity']&.strip&.to_i rescue 10) || 10,
          level: level,
          duration_hours: (row['duration_hours']&.strip&.to_d rescue 1.0) || 1.0
        )

        success_count += 1
        puts "✓ 成功创建课程: #{course.name} - #{course.start_time.strftime('%Y-%m-%d %H:%M')} (老师: #{teacher.name})"
      rescue ActiveRecord::RecordInvalid => e
        error_count += 1
        puts "✗ 创建课程失败: #{row['name']} - #{e.message}"
      rescue Date::Error, ArgumentError => e
        error_count += 1
        puts "✗ 日期格式错误: #{row['name']} - #{e.message}"
      rescue StandardError => e
        error_count += 1
        puts "✗ 未知错误: #{row['name']} - #{e.message}"
      end
    end

    puts "\n导入完成!"
    puts "成功: #{success_count} 条"
    puts "失败: #{error_count} 条"
  end

  desc "批量导入会员和课程数据. 使用: rake import:all[members_csv_path,courses_csv_path]"
  task :all, [:members_csv, :courses_csv] => :environment do |t, args|
    puts "===== 第一步: 导入会员数据 ====="
    Rake::Task['import:members'].invoke(args[:members_csv])

    puts "\n===== 第二步: 导入课程数据 ====="
    Rake::Task['import:courses'].reenable
    Rake::Task['import:courses'].invoke(args[:courses_csv])

    puts "\n===== 全部导入完成! ====="
  end
end
