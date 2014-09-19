class ChangeIdSize < ActiveRecord::Migration
  def change
  	remove_column :replies, :reply_id, :int
  	add_column :replies, :reply_id, :numeric
  end
end
