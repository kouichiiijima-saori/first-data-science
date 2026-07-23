require "test_helper"

class InitialAdminSeedTest < ActiveSupport::TestCase
  ENV_KEYS = %w[INITIAL_ADMIN_EMAIL INITIAL_ADMIN_PASSWORD].freeze

  setup do
    @original_env = ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    Admin.delete_all
  end

  teardown do
    ENV_KEYS.each do |key|
      if @original_env[key].nil?
        ENV.delete(key)
      else
        ENV[key] = @original_env[key]
      end
    end
  end

  test "creates one initial admin from environment variables" do
    with_initial_admin_env(email: "Admin@Example.COM", password: seed_password)

    stdout, = capture_io do
      assert_difference -> { Admin.count }, 1 do
        load_seed
      end
    end

    admin = Admin.find_by!(email: "admin@example.com")
    assert_includes stdout, "Initial admin created."
    assert_not_includes stdout, seed_password
    assert_not_nil admin.password_digest
  end

  test "normalizes email and authenticates with provided password" do
    with_initial_admin_env(email: "  ADMIN@Example.COM  ", password: seed_password)

    capture_io { load_seed }

    admin = Admin.find_by!(email: "admin@example.com")
    assert admin.authenticate(seed_password)
  end

  test "does not store plaintext password in database columns" do
    with_initial_admin_env(email: "admin@example.com", password: seed_password)

    capture_io { load_seed }

    admin = Admin.first
    assert_not_includes Admin.column_names, "password"
    assert_not_equal seed_password, admin.password_digest
    assert_not_includes admin.attributes.values.map(&:to_s), seed_password
  end

  test "does not create duplicates when run again with same email" do
    with_initial_admin_env(email: "admin@example.com", password: seed_password)
    capture_io { load_seed }

    assert_no_difference -> { Admin.count } do
      capture_io { load_seed }
    end
  end

  test "does not change password digest or updated at for existing admin" do
    with_initial_admin_env(email: "admin@example.com", password: seed_password)
    capture_io { load_seed }
    admin = Admin.find_by!(email: "admin@example.com")
    original_password_digest = admin.password_digest
    original_updated_at = admin.updated_at

    ENV["INITIAL_ADMIN_PASSWORD"] = "another-password"
    stdout, = capture_io { load_seed }

    admin.reload
    assert_includes stdout, "Initial admin seed skipped: admin already exists."
    assert_equal original_password_digest, admin.password_digest
    assert_equal original_updated_at, admin.updated_at
    assert admin.authenticate(seed_password)
    assert_not admin.authenticate("another-password")
  end

  test "skips initial admin creation in test when environment variables are not set" do
    clear_initial_admin_env

    stdout, = capture_io do
      assert_no_difference -> { Admin.count } do
        load_seed
      end
    end

    assert_includes stdout, "Initial admin seed skipped"
  end

  test "fails safely when email is invalid" do
    with_initial_admin_env(email: "not-an-email", password: seed_password)

    assert_no_difference -> { Admin.count } do
      assert_raises(ActiveRecord::RecordInvalid) do
        capture_io { load_seed }
      end
    end
  end

  test "fails safely when password is too short" do
    with_initial_admin_env(email: "admin@example.com", password: "short")

    assert_no_difference -> { Admin.count } do
      assert_raises(ActiveRecord::RecordInvalid) do
        capture_io { load_seed }
      end
    end
  end

  test "fails safely when only one required environment variable is set" do
    clear_initial_admin_env
    ENV["INITIAL_ADMIN_EMAIL"] = "admin@example.com"

    assert_no_difference -> { Admin.count } do
      error = assert_raises(RuntimeError) do
        capture_io { load_seed }
      end
      assert_equal "Both INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD are required to create the initial admin.", error.message
    end
  end

  private
    def load_seed
      load Rails.root.join("db/seeds.rb")
    end

    def with_initial_admin_env(email:, password:)
      ENV["INITIAL_ADMIN_EMAIL"] = email
      ENV["INITIAL_ADMIN_PASSWORD"] = password
    end

    def clear_initial_admin_env
      ENV_KEYS.each { |key| ENV.delete(key) }
    end

    def seed_password
      "seed-password-123"
    end
end
