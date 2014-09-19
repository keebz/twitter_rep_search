class CreateReplies < ActiveRecord::Migration
  def change
    create_table :replies do |t|
    	t.column :reply_id, :int
    	t.column :message, :string
    end
  end
end
