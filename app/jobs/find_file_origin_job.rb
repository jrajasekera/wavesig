class FindFileOriginJob < ApplicationJob
  queue_as :default

  def perform(original_file, leaker_file_path)
    leaker = ApplicationController.helpers.find_leak_source(original_file, leaker_file_path)

    findOriginResult = FindOriginResult.new :uploadedfile_id => original_file.id,
                                            :origin_user_id => (!leaker.nil? ? leaker.id : nil)
    findOriginResult.save
    runningJob = RunningJob.find_by(job_id: self.job_id)
    runningJob.destroy
  end

  rescue_from(StandardError) do |exception|
    original_file = arguments[0]
    leaker_file_path = arguments[1]
    pp "JOB DIDNT RUN PROPERLY!!!!!!!!!!!!!!!!!!!!!"
    findOriginResult = FindOriginResult.new :uploadedfile_id => original_file.id,
                                            :origin_user_id => (nil)
    findOriginResult.save

    File.delete(leaker_file_path) if File.exists? leaker_file_path
    runningJob = RunningJob.find_by(job_id: self.job_id)
    runningJob.destroy
  end

end
