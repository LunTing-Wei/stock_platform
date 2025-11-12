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

ActiveRecord::Schema[8.0].define(version: 2025_11_12_025404) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "balance", precision: 18, scale: 8, default: "0.0", null: false
    t.decimal "locked_balance", precision: 18, scale: 8, default: "0.0", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id", unique: true
    t.check_constraint "balance >= 0::numeric", name: "balance_non_negative"
    t.check_constraint "locked_balance >= 0::numeric", name: "locked_balance_non_negative"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "symbol", null: false
    t.integer "side", null: false
    t.decimal "quantity", precision: 18, scale: 8, null: false
    t.decimal "price", precision: 18, scale: 8, null: false
    t.integer "status", default: 0, null: false
    t.datetime "executed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["executed_at"], name: "index_orders_on_executed_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["symbol"], name: "index_orders_on_symbol"
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "symbol", null: false
    t.decimal "quantity", precision: 18, scale: 8, default: "0.0", null: false
    t.decimal "average_cost", precision: 18, scale: 8, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "symbol"], name: "index_positions_on_user_id_and_symbol", unique: true
    t.index ["user_id"], name: "index_positions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.string "transactionable_type"
    t.bigint "transactionable_id"
    t.integer "transaction_type", null: false
    t.decimal "amount", precision: 18, scale: 8, null: false
    t.decimal "balance_after", precision: 18, scale: 8, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_transactions_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["transactionable_type", "transactionable_id", "created_at"], name: "index_transactions_on_transactionable_and_created_at"
    t.index ["transactionable_type", "transactionable_id"], name: "index_transactions_on_transactionable"
    t.index ["user_id", "created_at"], name: "index_transactions_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "orders", "users"
  add_foreign_key "positions", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "users"
end
