# frozen_string_literal: true

require "test_helper"

class WeeklyStoreAuditSchedulerJobTest < ActiveJob::TestCase
  test "queues one audit per idle eligible shop" do
    assert_enqueued_jobs 2, only: StoreAuditJob do
      assert_difference -> { Audit.count }, 2 do
        WeeklyStoreAuditSchedulerJob.perform_now
      end
    end

    assert_equal 1, Audit.where(source: "weekly").count
    assert_equal 1, Audit.where(source: "install", shop: shops(:other_shop)).count
  end
end
