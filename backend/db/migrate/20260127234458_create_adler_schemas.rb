class CreateAdlerSchemas < ActiveRecord::Migration[8.1]
  def change
    create_table :adler_schemas do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :life_tasks
      t.jsonb :life_direction
      t.jsonb :private_logic
      t.jsonb :inferiorities
      t.jsonb :courage_usage
      t.jsonb :social_interest

      t.timestamps
    end
  end
end
