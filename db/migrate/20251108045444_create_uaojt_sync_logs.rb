class CreateUaojtSyncLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :uaojt_sync_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.date     :month,  null: false                    # e.g. 2025-11-01
      t.datetime :ran_at, null: false
      t.boolean  :success, null: false, default: false
      t.text     :message

      t.timestamps
    end
  end
end
