# frozen_string_literal: true

require 'zip'
require 'aws-sdk-lambda'

class MinimalPipeline
  # Here is an example of how to use this class to prepare zipfiles for lambda.
  #
  # ```
  # lambda = MinimalPipeline::Lambda.new
  # s3 = MinimalPipeline::S3.new
  #
  # # Prepare zip file
  # lambda.prepare_zipfile('foo.py', 'lambda.zip')
  #
  # # Upload file to S3
  # s3.upload('bucket_name', 'lambda.zip')
  # ```
  class Lambda
    # Zips up lambda code in preparation for upload
    #
    # @param input [String] The path to a file or directory to zip up
    # @param zipfile_name [String] The path to the resulting zip file
    def prepare_zipfile(input, zipfile_name)
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        if File.directory?(input)
          input_filenames = Dir.entries(input) - %w[. ..]
          input_filenames.each do |filename|
            zipfile.add(filename, File.join(input, filename))
          end
        else
          zipfile.add(File.basename(input), input)
        end
      end
    end
  end
end
