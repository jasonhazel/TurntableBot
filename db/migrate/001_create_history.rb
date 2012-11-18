class CreateHistory < ActiveRecord::Migration
  def self.up
    create_table :history do |t|
      t.string :song_id
      t.string :title
      t.string :artist
      t.string :dj_id
      t.string :dj_name
      t.integer :upvotes
      t.integer :downvotes
      t.integer :hearts
      t.integer :listeners
      t.timestamps
     end
  end

  def self.down
    drop_table :history
  end
end
