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

ActiveRecord::Schema[8.1].define(version: 2026_10_05_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "audiences", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "round_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contestants", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0
    t.bigint "round_id"
    t.integer "decision_rule"
    t.index ["round_id"], name: "index_contestants_on_round_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.string "title"
    t.bigint "owner_id"
    t.json "data", default: {}
    t.uuid "another_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "phone_number"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_role", default: 1
    t.uuid "another_id", default: -> { "gen_random_uuid()" }, null: false
    t.index ["another_id"], name: "index_users_on_another_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "contestant_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "audience_id", null: false
    t.integer "choice", default: 0, null: false
    t.index ["audience_id", "contestant_id"], name: "index_votes_on_audience_id_and_contestant_id", unique: true
    t.index ["contestant_id"], name: "index_votes_on_contestant_id"
  end

  add_foreign_key "votes", "audiences"
end
