# This file contains the fastlane.tools configuration
# You can find the documentation at https://docs.fastlane.tools
#
# For a list of all available actions, check out
#
#     https://docs.fastlane.tools/actions
#
# For a list of all available plugins, check out
#
#     https://docs.fastlane.tools/plugins/available-plugins
#

# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:android)

platform :android do
  desc "Deploy a new version to the Google Play"
  lane :deploy do
	gradle(
	  task: 'assemble',
	  build_type: 'Release'
	)
    # upload_to_play_store
    gradle(task: "clean assembleRelease")
  end
end
