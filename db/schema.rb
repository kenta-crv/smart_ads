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

ActiveRecord::Schema[7.1].define(version: 2025_10_10_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "campaign_results", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "push_subscription_id", null: false
    t.string "status", null: false
    t.datetime "delivered_at"
    t.datetime "clicked_at"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaign_results_on_campaign_id"
    t.index ["push_subscription_id"], name: "index_campaign_results_on_push_subscription_id"
    t.index ["status"], name: "index_campaign_results_on_status"
  end

  create_table "campaigns", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "icon_url"
    t.string "target_url"
    t.jsonb "targeting_conditions", default: {}
    t.datetime "scheduled_at"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_at"], name: "index_campaigns_on_scheduled_at"
    t.index ["status"], name: "index_campaigns_on_status"
    t.index ["user_id"], name: "index_campaigns_on_user_id"
  end

  create_table "install_scripts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "script_code", null: false
    t.string "version", default: "1.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_install_scripts_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "campaign_id", null: false
    t.integer "amount", null: false
    t.string "payjp_charge_id", null: false
    t.string "status", default: "pending", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_payments_on_campaign_id"
    t.index ["payjp_charge_id"], name: "index_payments_on_payjp_charge_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.jsonb "keys", default: {}, null: false
    t.string "browser", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plan_type", null: false
    t.string "status", default: "active", null: false
    t.datetime "trial_ends_at"
    t.string "payjp_subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payjp_subscription_id"], name: "index_subscriptions_on_payjp_subscription_id"
    t.index ["plan_type"], name: "index_subscriptions_on_plan_type"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_name", default: "", null: false
    t.string "domain", default: "", null: false
    t.string "api_key", default: "", null: false
    t.string "subscription_plan", default: "trial"
    t.string "subscription_status", default: "active"
    t.datetime "trial_ends_at"
    t.string "payjp_customer_id"
    t.index ["api_key"], name: "index_users_on_api_key"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["subscription_plan"], name: "index_users_on_subscription_plan"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  add_foreign_key "campaign_results", "campaigns"
  add_foreign_key "campaign_results", "push_subscriptions"
  add_foreign_key "campaigns", "users"
  add_foreign_key "install_scripts", "users"
  add_foreign_key "payments", "campaigns"
  add_foreign_key "payments", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "subscriptions", "users"
end
