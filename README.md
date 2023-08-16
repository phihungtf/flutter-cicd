# Flutter CI/CD

## Introduction

Simple Flutter CI/CD with Jenkins, Docker and Fastlane. The purpose of this project is to show how to setup a CI/CD pipeline for Flutter apps. The pipeline will run tests, create a release build and upload it to Google Play Store whenever a new commit is pushed to the repository on a specific branch. The job will be triggered by polling the repository every 5 minutes.

## Prerequisites

- Docker

- Ruby with Fastlane installed

## Setup

### Build the Docker image

The Dockerfile is based on the official Jenkins Docker image. It installs Android SDK, Flutter and Fastlane.

> By default, the Docker image only installs the `platforms;android-29`, `platforms;android-31` and `platforms;android-33` Android SDK packages. If you need other packages, you can add them in the Dockerfile.

![Platforms](/images/android-platforms.png)

Run the following command to build the Docker image from the Dockerfile:

```bash
docker build -t jenkinsflutter .
```

### Run the Docker container

Run the following command to run the Docker container:

```bash
docker run -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home --name jenkinsflutter jenkinsflutter
```

![Run Docker container](/images/run-docker.png)

Store the initial admin password from the console output. You will need it to unlock Jenkins.

### Setup Jenkins

Open a browser and go to http://localhost:8080. Unlock Jenkins with the initial admin password.

![Unlock Jenkins](/images/unlock-jenkins.png)

Click `Continue` and `Install suggested plugins`.

![Install suggested plugins](/images/install-plugins.png)

Wait for the installation to complete and create an admin user.

![Create admin user](/images/create-admin-user.png)

Click `Save and Continue`. Leave the Jenkins URL as it is and click `Save and Finish` then `Start using Jenkins`.

Now you are ready to use Jenkins.

> If you want to use a different port than 8080, you can change it in the Docker run command.

> The account you just created is a Jenkins admin user. You will need it to access Jenkins.

### Create a new Jenkins job

In the Jenkins dashboard, click `New Item`. Enter a name for the job and select `Multibranch Pipeline` then click `OK`.

![Create new job](/images/new-job.png)

In the `Branch Sources` section, click `Add source` then `Git`. Enter the repository URL and credentials. In my case, I am using a private repository on GitHub and SSH credentials:

- Enter the repository URL: `git@github.com:phihungtf/flutter-ocr.git`
- Click `Add` in the `Credentials` section, choose where you want to store the credentials (Jenkins for global credentials or the job for job-specific credentials). In my case, Jenkins is fine.

![Add credentials](/images/add-credentials.png)

- Select `SSH Username with private key` in the `Kind` dropdown list.
- Check `Treating SSH keys as secret`.
- Choose `Enter directly`, click `Add` and paste your private key associated with the SSH key you added to your GitHub account in the `Private Key` field.

![SSH credentials](/images/ssh-credentials.png)

> More information about how to generate an SSH key and add it to your GitHub account can be found [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

- Click `Add` to finish adding the credentials.
- **Select the credentials you just added in the `Credentials` dropdown list.**

![Select credentials](/images/select-credentials.png)

- Click `Save`.

> If getting an error, you might have to disable the `Host Key Verification` if you are using a private repository on GitHub. To do so, navigate to `Dashboard` > `Manage Jenkins` > `Security` > `Git Host Key Verification Configuration` and set the `Host Key Verification Strategy` to `No verification` then click `Save`.

![Host Key Verification](/images/host-key-verification.png)

> Navigate back to the job and click `Scan Multibranch Pipeline Now` to scan the repository branches.

![Scan Multibranch Pipeline](/images/scan-multibranch-pipeline.png)

Now Jenkins should have detected the branches in the repository.

## Configure the repository

### Add Jenkinsfile

Add a `Jenkinsfile` to the repository root directory. This file contains the pipeline configuration.

```groovy
pipeline {
    agent any

	triggers {
    	pollSCM('*/5 * * * *')
	}

    stages {
		stage ('FLUTTER DOCTOR') {
            steps {
                sh "flutter doctor -v"
            }
        }
        // stage('TEST') {
        //     steps {
        //         sh 'flutter test'
        //     }
        // }
        stage('BUILD') {
            steps {
                sh 'flutter build appbundle --debug'
            }
        }
		stage('DEPLOY') {
			steps {
				sh 'cd android && fastlane android deploy'
			}
		}
	}
}
```

- The `agent` section specifies where the pipeline will run. In this case, it will run on any available agent.
- The `triggers` section specifies when the pipeline will be triggered. In this case, it will be triggered every 5 minutes.
- The `stages` section specifies the stages of the pipeline. In this case, there are 3 stages: `FLUTTER DOCTOR`, `BUILD` and `DEPLOY`.

> The `TEST` stage is commented out because it is not necessary for this project. You can uncomment it if you want to run tests.
> If you don't want to run deployment every time a new commit is pushed to the repository, you can comment out the `DEPLOY` stage. Or you can create a new branch and push to that branch to trigger the deployment.

### Add fastlane

Run the following command in the repository root directory to initialize fastlane:

```bash
cd android && fastlane init
```

You'll be asked a few pieces of information. To get started quickly:

- Provide the package name of your Android app. You can find it in the `AndroidManifest.xml` file in the `android/app/src/main` directory.
- Press enter when asked for the path to your json secret file (we will add the path later).
- Answer 'n` when asked if you plan on uploading info to Google Play via fastlane (we can set this up later).
- Press `Enter` a few times to confirm.

![Initialize Fastlane](/images/fastlane-init.png)

Now in the `android` directory, you should see a `fastlane` directory with a `Fastfile` and a `Appfile`.

Replace the `Fastfile` with the following content:

```ruby
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
```

> Note that the `upload_to_play_store` action is commented out. We will uncomment it later when we have the json secret file.

Now we have everything we need to run the pipeline.

### Run the pipeline

Create and push a new commit to the repository that has the `Jenkinsfile` and the `fastlane` directory.

In the Jenkins dashboard, click on the job you created earlier. Click `Scan Multibranch Pipeline Now` to scan the repository branches.

The pipeline should be triggered within 5 minutes. You can click on the job to see the pipeline progress.

![Pipeline progress](/images/pipeline-progress.png)

The pipeline should run without any errors. If you get an error, you can check the console output to see what went wrong.

![Pipeline console output](/images/pipeline-console-output.png)

## Deploy to Google Play Store

In order to deploy to Google Play Store, first we need to collect our Google Play credentials.

> Tip: If you see Google Play Console or Google Developer Console in your local language, add `&hl=en` at the end of the URL (before any `#...`) to switch to English.

1. Open the [Google Play Console](https://play.google.com/console/)
2. Click **Account Details**, and note the **Developer Account ID** listed there
3. Click **Setup** → **API access**
4. Click the **Create new service account** button
5. Follow the **Google Cloud Platform** link in the dialog, which opens a new tab/window:
   - Click the **CREATE SERVICE ACCOUNT** button at the top of the Googl**e Cloud Platform Console**
   - Verify that you are on the correct Google Cloud Platform Project by looking for the **Developer Account ID** from earlier within the light gray text in the second input, preceding `.iam.gserviceaccount.com`. If not, open the picker in the top navigation bar, and find the one with the **ID** that contains it.
   - Provide a `Service account name` and click **Create**
   - Click **Select a role**, then find and select **Service Account User**, and proceed
   - Click the **Done** button
   - Click on the **Actions** vertical three-dot icon of the service account you just created
   - Select **Manage keys** on the menu
   - Click **ADD KEY** -> **Create New Key**
   - Make sure **JSON** is selected as the `Key type`, and click **CREATE**
   - Save the file on your computer when prompted and remember where it was saved to
6. Return to the **Google Play Console** tab, and click **DONE** to close the dialog
7. Click on **Grant Access** for the newly added service account at the bottom of the screen (you may need to click **Refresh service accounts** before it shows up)
8. Choose the permissions you'd like this account to have. We recommend **Admin (all permissions)**, but you may want to manually select all checkboxes and leave out some of the **Releases** permissions such as **Release to production**
9. Click **Invite user** to finish

You can use `fastlane run validate_play_store_json_key json_key:/path/to/your/downloaded/file.json` to test the connection to Google Play Store with the downloaded private key. Once that works, add the path to the JSON file to your [Appfile](https://docs.fastlane.tools/advanced/Appfile):

```ruby
json_key_file("path/to/your/play-store-credentials.json")
package_name("my.package.name")
```

The path is relative to where you normally run `fastlane`.

> More information can be found [here](https://docs.fastlane.tools/getting-started/android/setup/#setting-up-supply).

Now you can uncomment the `upload_to_play_store` action in the `Fastfile` and push a new commit to the repository to trigger the pipeline.
