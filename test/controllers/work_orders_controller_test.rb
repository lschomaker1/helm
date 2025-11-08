require "test_helper"

class WorkOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get work_orders_index_url
    assert_response :success
  end

  test "should get show" do
    get work_orders_show_url
    assert_response :success
  end

  test "should get new" do
    get work_orders_new_url
    assert_response :success
  end

  test "should get create" do
    get work_orders_create_url
    assert_response :success
  end

  test "should get edit" do
    get work_orders_edit_url
    assert_response :success
  end

  test "should get update" do
    get work_orders_update_url
    assert_response :success
  end

  test "should get destroy" do
    get work_orders_destroy_url
    assert_response :success
  end
end
