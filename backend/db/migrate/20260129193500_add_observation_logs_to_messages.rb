class AddObservationLogsToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :observation_logs, :jsonb, default: []
  end
end
