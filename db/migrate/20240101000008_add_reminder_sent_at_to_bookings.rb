class AddReminderSentAtToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :reminder_sent_at, :datetime
    add_index :bookings, :reminder_sent_at
  end
end
