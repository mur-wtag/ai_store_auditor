# frozen_string_literal: true

require "test_helper"

class WeeklyStoreAuditSchedulerJobTest < ActiveJob::TestCase
  test "queues one weekly audit per idle shop" do
    assert_enqueued_jobs 2, only: StoreAuditJob do
      assert_difference -> { Audit.where(source: "weekly").count }, 2 do
        WeeklyStoreAuditSchedulerJob.perform_now
      end
    end
  end
end
