class CreateSchemaMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :schema_mappings do |t|
      t.references :adler_schema, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.string :field
      t.text :value
      t.float :confidence
      t.boolean :confirmed
      t.text :source_text

      t.timestamps
    end
  end
end
