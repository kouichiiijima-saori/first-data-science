require "test_helper"

class AdminTest < ActiveSupport::TestCase
  test "authenticates with password without storing plaintext" do
    admin = Admin.create!(email: "admin@example.com", password: "password123")

    assert admin.authenticate("password123")
    assert_not_equal "password123", admin.password_digest
  end

  test "normalizes email before saving" do
    admin = Admin.create!(email: "  Admin@Example.COM  ", password: "password123")

    assert_equal "admin@example.com", admin.email
  end

  test "requires email" do
    admin = Admin.new(email: " ", password: "password123")

    assert_not admin.valid?
    assert_includes admin.errors[:email], "can't be blank"
  end

  test "rejects duplicate email ignoring case" do
    Admin.create!(email: "admin@example.com", password: "password123")
    duplicate = Admin.new(email: "ADMIN@example.com", password: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "enforces unique email at the database layer" do
    Admin.create!(email: "admin@example.com", password: "password123")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Admin.insert_all!([
        { email: "admin@example.com", password_digest: "digest", created_at: Time.current, updated_at: Time.current }
      ])
    end
  end
end
