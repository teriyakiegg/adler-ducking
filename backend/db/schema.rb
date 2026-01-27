# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_27_234501) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "adler_schemas", force: :cascade do |t|
    t.jsonb "courage_usage"
    t.datetime "created_at", null: false
    t.jsonb "inferiorities"
    t.jsonb "life_direction"
    t.jsonb "life_tasks"
    t.jsonb "private_logic"
    t.jsonb "social_interest"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_adler_schemas_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "schema_mappings", force: :cascade do |t|
    t.bigint "adler_schema_id", null: false
    t.float "confidence"
    t.boolean "confirmed"
    t.datetime "created_at", null: false
    t.string "field"
    t.bigint "message_id", null: false
    t.text "source_text"
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["adler_schema_id"], name: "index_schema_mappings_on_adler_schema_id"
    t.index ["message_id"], name: "index_schema_mappings_on_message_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "adler_schemas", "users"
  add_foreign_key "conversations", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "schema_mappings", "adler_schemas"
  add_foreign_key "schema_mappings", "messages"
end
