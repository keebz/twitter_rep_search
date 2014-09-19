class FixReplies < ActiveRecord::Migration
  def change
  	remove_column :replies, :reply_id, :numeric
  	add_column :replies, :reply_id, :string
  end
end
